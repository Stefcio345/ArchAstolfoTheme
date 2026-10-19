"""Regression checks for corner anchoring across actual desktop window shapes."""
import importlib.util
import contextlib
import io
import os
import pty
from pathlib import Path
import re
import select
import shlex
import subprocess
import sys
import tempfile
import time
import types
import unittest
from unittest.mock import patch

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "kitty/astolfo-goth/responsive_background.py"


class BackgroundLayoutTests(unittest.TestCase):
    def renderer(self):
        self.assertTrue(RENDERER.is_file(), "Missing resize-aware background renderer")
        spec = importlib.util.spec_from_file_location("responsive_background", RENDERER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_all_corners_remain_visible_in_wide_and_portrait_windows(self):
        renderer = self.renderer()
        with tempfile.TemporaryDirectory() as folder:
            for width, height in [(924, 475), (924, 976), (2514, 655), (480, 1000)]:
                with self.subTest(size=(width, height)):
                    result = renderer.render_background(width, height, Path(folder))
                    with Image.open(result) as image:
                        self.assertEqual(image.size, (width, height))
                        side = min(width, height) // 3
                        for box in [(0, 0, side, side), (width-side, 0, width, side),
                                    (0, height-side, side, height),
                                    (width-side, height-side, width, height)]:
                            pixels = image.crop(box).load()
                            rose_pixels = sum(pixels[x, y][0] > pixels[x, y][1] + 5
                                              for x in range(side) for y in range(side))
                            self.assertGreater(rose_pixels, 40, f"Missing corner in {box}")
                        self.assertEqual(image.getpixel((width // 3, height // 2)), (26, 27, 31))

    def test_parts_fit_inside_the_window_without_distortion(self):
        renderer = self.renderer()
        for width, height in [(924, 475), (2514, 655), (480, 1000), (120, 80)]:
            boxes = renderer.placements(width, height)
            self.assertEqual(set(boxes), {"top_left", "top_right", "bottom_left", "bottom_right", "crest"})
            for x, y, w, h in boxes.values():
                self.assertGreaterEqual(x, 0)
                self.assertGreaterEqual(y, 0)
                self.assertLessEqual(x+w, width)
                self.assertLessEqual(y+h, height)
            # The original upper-left ornament's crop is 367 x 296 pixels.
            _, _, w, h = boxes["top_left"]
            self.assertAlmostEqual(w / 367, h / 296, delta=0.007)
            x, y, w, h = boxes["bottom_right"]
            self.assertEqual((x+w, y+h), (width, height))

    def test_repeated_window_size_reuses_the_cached_image(self):
        renderer = self.renderer()
        with tempfile.TemporaryDirectory() as folder:
            first = renderer.render_background(924, 475, Path(folder))
            timestamp = first.stat().st_mtime_ns
            second = renderer.render_background(924, 475, Path(folder))
            self.assertEqual(first, second)
            self.assertEqual(second.stat().st_mtime_ns, timestamp)

    def test_watcher_uses_kitty_metrics_and_latest_resize(self):
        renderer = self.renderer()
        metrics = {"width": 924, "height": 976, "cell_width": 10, "cell_height": 22,
                   "xscale": 1.0, "yscale": 1.0, "is_layer_shell": False}
        timers, applied = [], []
        native = types.ModuleType("kitty.fast_data_types")
        native.get_os_window_size = lambda os_id: metrics.copy()
        native.add_timer = lambda callback, delay, repeat: timers.append(callback)
        boss = types.SimpleNamespace(os_window_map={7: object()},
                                     set_background_image=lambda *args: applied.append(args))
        window = types.SimpleNamespace(os_window_id=7)
        with tempfile.TemporaryDirectory() as folder, patch.dict(sys.modules, {"kitty.fast_data_types": native}), \
                patch.dict(os.environ, {"XDG_CACHE_HOME": folder}):
            try:
                renderer.on_resize(boss, window, {})
                metrics.update(width=924, height=475)
                renderer.on_resize(boss, window, {})
            except AttributeError as exc:
                self.fail(f"Kitty returns dictionary metrics, not object attributes: {exc}")
            timers[0](0)
            self.assertEqual(applied[0][1:], ((7,), False, "scaled"))
            with Image.open(applied[0][0]) as image:
                self.assertEqual(image.size, (924, 475))


class ShortTerminalTests(unittest.TestCase):
    def test_completed_commands_keep_their_right_prompt(self):
        result = self.run_theme('print -r -- $options[transientrprompt]')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "off")

    def test_submit_refreshes_timestamp_after_waiting_at_the_prompt(self):
        master, slave = pty.openpty()
        environment = os.environ.copy()
        environment.update(TERM="xterm-256color", TERM_PROGRAM="vscode")
        process = subprocess.Popen(["zsh", "-d", "-f", "-i"], stdin=slave, stdout=slave,
                                   stderr=slave, env=environment, start_new_session=True)
        os.close(slave)

        def read_until(pattern):
            output = b""
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.1)[0]:
                    output += os.read(master, 65536)
                    if re.search(pattern, output):
                        return output
            self.fail(f"PTY output never matched {pattern!r}: {output!r}")

        try:
            setup = ("typeset -A ZSH_HIGHLIGHT_STYLES; source " +
                     shlex.quote(str(ROOT / "zsh/themes/franke.zsh-theme")) +
                     "; PROMPT='TEST> '; RPROMPT='STAMP%D{%s}'; print READY\n")
            os.write(master, setup.encode())
            initial = read_until(rb"STAMP[0-9]{10}")
            before = int(re.findall(rb"STAMP([0-9]{10})", initial)[-1])
            time.sleep(1.1)
            # Split the output marker so it cannot match the echoed command.
            os.write(master, b"print FINISHED$'_'COMMAND\n")
            submitted = read_until(rb"FINISHED_COMMAND")
            refreshed = re.findall(rb"STAMP([0-9]{10})", submitted.split(b"FINISHED_COMMAND")[0])
            self.assertTrue(refreshed, "Submitting must refresh the right-hand time before execution")
            self.assertGreater(int(refreshed[-1]), before)
        finally:
            try:
                os.write(master, b"exit\n")
                process.wait(timeout=1)
            except (OSError, subprocess.TimeoutExpired):
                process.kill()
                process.wait(timeout=5)
            finally:
                os.close(master)

    def frame_module(self):
        spec = importlib.util.spec_from_file_location("frame_logo", ROOT / "kitty/astolfo-goth/frame_logo.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_thin_panel_has_no_text_and_reserves_rows_below_the_picture(self):
        module = self.frame_module()
        self.assertTrue(hasattr(module, "panel_layout"), "Panel needs explicit image and prompt geometry")
        panel = module.panel_layout((100, 100), (43, 40, 400, 946), ["SYSTEM " + "x" * 50], 2)
        self.assertIsNone(panel["text"])
        x, y, width, height = panel["image"]
        self.assertEqual(x, (40 - width) // 2)
        self.assertGreater(panel["next_row"], y + height)
        self.assertLess(panel["next_row"] + 3, 43)

    def test_medium_panel_clears_corner_and_fits_actual_text(self):
        module = self.frame_module()
        self.assertTrue(hasattr(module, "panel_layout"))
        lines = ["x" * 54] * 13
        panel = module.panel_layout((400, 432), (43, 90, 900, 946), lines, 2)
        x, y, width, height = panel["image"]
        text_x, text_y = panel["text"]
        self.assertGreaterEqual(x, 7)
        self.assertGreaterEqual(text_x, x + width + 3)
        self.assertLessEqual(text_x + 54, 90)
        self.assertGreater(panel["next_row"], max(y + height, text_y + 13))

    def test_short_portrait_panel_never_extends_into_prompt_rows(self):
        module = self.frame_module()
        self.assertTrue(hasattr(module, "panel_layout"))
        panel = module.panel_layout((100, 300), (18, 40, 400, 396), [], 0)
        x, y, width, height = panel["image"]
        self.assertLessEqual(height, 13)
        self.assertLessEqual(panel["next_row"] + 3, 18)

    def test_panel_renders_supplied_shell_info_without_redetecting_its_parent(self):
        module = self.frame_module()
        with tempfile.TemporaryDirectory() as folder:
            image = Path(folder) / "logo.png"
            Image.new("RGB", (100, 100)).save(image)
            with patch("fcntl.ioctl", return_value=__import__("struct").pack("HHHH", 43, 90, 900, 946)), \
                    patch.object(module.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as run, \
                    contextlib.redirect_stdout(io.StringIO()) as output:
                module.draw_panel(image, 2, ["SHELL zsh 5.9.2"])
            self.assertIn("SHELL zsh 5.9.2", output.getvalue())
            self.assertEqual([call.args[0][0] for call in run.call_args_list], ["kitten"])

    def test_very_narrow_terminal_uses_explicit_panel_renderer(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            renderer = root / "kitty/astolfo-goth/frame_logo.py"
            renderer.parent.mkdir(parents=True)
            renderer.write_text("import sys\nprint('PANEL:' + ' '.join(sys.argv[1:]))\n")
            result = self.run_theme("LINES=43; COLUMNS=40; FASTFETCH_LOGO=/tmp/example-logo.png; "
                                    "run_fastfetch_random_logo", root)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("PANEL:--panel /tmp/example-logo.png 2", result.stdout)

    def run_theme(self, body, config="/tmp/no-dotfiles-fixture"):
        script = ("typeset -A ZSH_HIGHLIGHT_STYLES; TERM_PROGRAM=vscode; source " +
                  shlex.quote(str(ROOT / "zsh/themes/franke.zsh-theme")) +
                  "; unset TERM_PROGRAM; XDG_CONFIG_HOME=" + shlex.quote(str(config)) + "; " + body)
        return subprocess.run(["zsh", "-d", "-f", "-i", "-c", script], capture_output=True, text=True)

    def test_resize_redraws_welcome_without_losing_partially_typed_command(self):
        result = self.run_theme("BUFFER='echo not executed'; CURSOR=7; "
                                "zle() { return 0; }; run_fastfetch_random_logo() { print REFLOW; }; "
                                "TRAPWINCH; print -r -- \"BUFFER=$BUFFER CURSOR=$CURSOR\"")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("REFLOW", result.stdout)
        self.assertIn("BUFFER=echo not executed CURSOR=7", result.stdout)

    def test_resize_during_a_draw_replays_the_latest_size_instead_of_dropping_it(self):
        result = self.run_theme("COLUMNS=120; LINES=43; integer draws=0; "
                                "zle() { return 0; }; "
                                "run_fastfetch_random_logo() { "
                                "(( draws++ )); print DRAW:$COLUMNS:$LINES; "
                                "if (( draws == 1 )); then COLUMNS=40; LINES=21; TRAPWINCH; fi; }; "
                                "TRAPWINCH; print BUSY:$ASTOLFO_WELCOME_DRAWING")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("DRAW:120:43", result.stdout)
        self.assertIn("DRAW:40:21", result.stdout)
        self.assertEqual(result.stdout.count("DRAW:"), 2)
        self.assertIn("BUSY:0", result.stdout)

    def test_resize_before_editor_starts_is_replayed_on_line_init(self):
        result = self.run_theme("zle() { return 1; }; "
                                "run_fastfetch_random_logo() { print DRAW; }; TRAPWINCH; "
                                "zle() { return 0; }; astolfo_welcome_line_init")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count("DRAW"), 1)

    def test_draw_rechecks_size_when_the_shell_coalesces_resize_signals(self):
        result = self.run_theme("COLUMNS=120; LINES=43; integer draws=0; "
                                "zle() { return 0; }; run_fastfetch_random_logo() { "
                                "(( draws++ )); print DRAW:$COLUMNS:$LINES; "
                                "if (( draws == 1 )); then COLUMNS=40; LINES=21; fi; }; TRAPWINCH")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("DRAW:40:21", result.stdout)
        self.assertEqual(result.stdout.count("DRAW:"), 2)

    def test_resize_invalidates_then_refreshes_without_repositioning_old_prompt(self):
        result = self.run_theme("zle() { [[ $1 == reset-prompt ]] && print RESET; "
                                "[[ $1 == -I ]] && print INVALIDATE; "
                                "[[ $1 == -R ]] && print REFRESH; return 0; }; "
                                "run_fastfetch_random_logo() { print PANEL; }; TRAPWINCH")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("RESET", result.stdout,
                         "Calling a redisplay widget consumes the invalidation before the new panel is drawn")
        self.assertLess(result.stdout.index("INVALIDATE"), result.stdout.index("PANEL"))
        self.assertIn("REFRESH", result.stdout)
        self.assertLess(result.stdout.index("PANEL"), result.stdout.index("REFRESH"))

    def test_wide_kitty_greeting_uses_only_one_text_row(self):
        with tempfile.TemporaryDirectory() as folder:
            kitten = Path(folder) / "kitten"
            kitten.write_text("#!/bin/sh\nprintf 'BITMAP ROW 1\\nBITMAP ROW 2\\nBITMAP ROW 3\\n'\n")
            kitten.chmod(0o755)
            environment = os.environ.copy()
            environment.update(PATH=folder + ":" + environment["PATH"], COLUMNS="120",
                               KITTY_WINDOW_ID="1", XDG_CONFIG_HOME=str(ROOT))
            result = subprocess.run(["zsh", str(ROOT / "scripts/CuteMessage.sh")],
                                    env=environment, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            visible = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", result.stdout)
            self.assertEqual(len([line for line in visible.splitlines() if line.strip()]), 1)

    def test_resize_preserves_the_screen_after_running_commands(self):
        script = ("typeset -A ZSH_HIGHLIGHT_STYLES; TERM_PROGRAM=vscode; source " +
                  shlex.quote(str(ROOT / "zsh/themes/franke.zsh-theme")) +
                  "; unset TERM_PROGRAM; ASTOLFO_WELCOME_PRISTINE=0; LINES=21; COLUMNS=90; "
                  "XDG_CONFIG_HOME=/tmp/no-dotfiles-fixture; fastfetch() { print FETCH; }; TRAPWINCH")
        result = subprocess.run(["zsh", "-d", "-f", "-i", "-c", script],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "", "Resizing must not clear or redraw over command output")

    def test_image_width_matches_text_height_for_different_aspect_ratios(self):
        path = ROOT / "kitty/astolfo-goth/frame_logo.py"
        spec = importlib.util.spec_from_file_location("frame_logo", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertTrue(hasattr(module, "display_columns"), "Image sizing ignores terminal cell geometry")
        with tempfile.TemporaryDirectory() as folder:
            for size, expected in [((100, 100), 28), ((100, 200), 14), ((400, 432), 26)]:
                image = Path(folder) / "logo.png"
                Image.new("RGB", size).save(image)
                self.assertEqual(module.display_columns(image, (21, 89, 890, 462)), expected)

    def test_narrow_layout_reserves_text_space_and_centers_the_smaller_picture(self):
        spec = importlib.util.spec_from_file_location("frame_logo", ROOT / "kitty/astolfo-goth/frame_logo.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertTrue(hasattr(module, "display_layout"), "Narrow terminals need a centered smaller picture")
        with tempfile.TemporaryDirectory() as folder:
            image = Path(folder) / "logo.png"
            Image.new("RGB", (100, 100)).save(image)
            columns, top = module.display_layout(image, (40, 73, 730, 880))
            self.assertEqual(columns, 17)
            self.assertEqual(top, 2)

    def test_short_terminal_keeps_header_and_large_footer_from_scrolling_off_logo(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "scripts").mkdir()
            (root / "kitty/astolfo-goth").mkdir(parents=True)
            header = root / "scripts/CuteMessage.sh"
            header.write_text("#!/bin/sh\necho LARGE_HEADER\n")
            header.chmod(0o755)
            (root / "kitty/astolfo-goth/winged-cross.png").touch()
            for name, message in [("fastfetch", "FETCH_TEXT"), ("kitten", "LARGE_FOOTER")]:
                script = root / name
                script.write_text(f"#!/bin/sh\necho {message}\n")
                script.chmod(0o755)
            environment = os.environ.copy()
            environment["PATH"] = str(root) + ":" + environment["PATH"]
            script = ("typeset -A ZSH_HIGHLIGHT_STYLES; TERM_PROGRAM=vscode; source " + shlex.quote(str(ROOT / "zsh/themes/franke.zsh-theme")) +
                      "; unset TERM_PROGRAM; export XDG_CONFIG_HOME=" + shlex.quote(str(root)) +
                      "; LINES=21; COLUMNS=90; FASTFETCH_LOGO=; run_fastfetch_random_logo")
            result = subprocess.run(["zsh", "-d", "-f", "-i", "-c", script], env=environment,
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("FETCH_TEXT", result.stdout)
            self.assertNotIn("LARGE_HEADER", result.stdout)
            self.assertNotIn("LARGE_FOOTER", result.stdout)


if __name__ == "__main__":
    unittest.main()
