"""Exercise restore safety without touching the real home directory."""
import importlib.machinery
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader("dotfiles_cli", str(SOURCE / "dotfiles"))
spec = importlib.util.spec_from_loader(loader.name, loader)
cli = importlib.util.module_from_spec(spec)
loader.exec_module(cli)


class RestoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.base = Path(self.temp.name)
        self.home = self.base / "new home"
        self.home.mkdir()

    def tearDown(self):
        self.temp.cleanup()

    def invoke(self, *args, root=SOURCE, success=True):
        result = subprocess.run([str(root / "dotfiles"), *args], capture_output=True, text=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def install(self, *args, **kwargs):
        return self.invoke("install", "--home", str(self.home), *args, **kwargs)

    def test_dry_run_does_not_write(self):
        self.install("--dry-run")
        self.assertEqual(list(self.home.iterdir()), [])

    def test_backups_preserve_directory_file_and_broken_link(self):
        old = self.home / ".config/kitty"
        old.mkdir(parents=True)
        (old / "personal.conf").write_text("keep me")
        (self.home / ".zshenv").write_text("old shell")
        broken = self.home / ".config/mako"
        broken.symlink_to("missing-old-config")
        self.install()
        backups = list((self.home / ".local/state/dotfiles/backups").iterdir())
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / ".config/kitty/personal.conf").read_text(), "keep me")
        self.assertEqual((backups[0] / ".zshenv").read_text(), "old shell")
        self.assertEqual(os.readlink(backups[0] / ".config/mako"), "missing-old-config")
        for source, destination in cli.mappings(self.home):
            self.assertEqual(destination.resolve(), source.resolve())

    def test_second_install_does_not_create_extra_backups(self):
        self.install()
        result = self.install()
        self.assertNotIn("LINK ", result.stdout)
        self.assertFalse((self.home / ".local/state/dotfiles/backups").exists())

    def test_unmanaged_app_data_is_preserved(self):
        personal = self.home / ".config/gtk-3.0/bookmarks"
        personal.parent.mkdir(parents=True)
        personal.write_text("personal bookmarks")
        self.install()
        self.assertEqual(personal.read_text(), "personal bookmarks")

    def test_renamed_checkout_with_spaces_and_shell_startup(self):
        clone = self.base / "renamed theme"
        clone.mkdir()
        shutil.copy2(SOURCE / "dotfiles", clone / "dotfiles")
        shutil.copy2(SOURCE / "config-paths.txt", clone / "config-paths.txt")
        # Copy the actual managed source tree, excluding machine-local files.
        for source, _ in cli.mappings(self.home):
            dest = clone / source.relative_to(SOURCE)
            if dest.exists():
                continue
            dest.parent.mkdir(parents=True, exist_ok=True)
            if source.is_dir():
                shutil.copytree(source, dest, ignore=shutil.ignore_patterns(
                    ".git", "ohmyzsh", "hyprsplit", "local.lua", "local.env", "local.zsh"))
            else:
                shutil.copy2(source, dest)
        # The ignore pattern excludes dependencies too; restore the small vendors.
        shutil.copytree(SOURCE / "zsh/vendor", clone / "zsh/vendor", dirs_exist_ok=True)
        shutil.copytree(SOURCE / "hypr/lib", clone / "hypr/lib", dirs_exist_ok=True)
        self.install(root=clone)
        environment = os.environ.copy()
        environment.update(ZDOTDIR=str(self.home / ".config/zsh"),
                           XDG_CACHE_HOME=str(self.base / "cache"), TERM_PROGRAM="vscode")
        result = subprocess.run(["zsh", "-d", "-i", "-c",
                                 'print -r -- "$XDG_CONFIG_HOME"; whence -w dotfiles; '
                                 '[[ "$ZSH_THEME" == franke && -n "$PROMPT" ]]'],
                                env=environment, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(str(clone), result.stdout)
        self.assertIn("dotfiles: function", result.stdout)
        self.assertNotIn("not found", result.stderr)
        self.assertNotIn("no such file", result.stderr)

    def test_root_home_is_rejected(self):
        self.invoke("install", "--home", "/", "--dry-run", success=False)


class GitWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-git-test-")
        self.base = Path(self.temp.name)
        self.repo = self.base / "repo"
        self.repo.mkdir()
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Restore Test")
        self.git("config", "user.email", "restore@example.invalid")
        (self.repo / "theme.conf").write_text("pink\n")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.repo, check=True,
                              capture_output=True, text=True).stdout

    def test_save_commits_and_pushes_to_local_remote(self):
        remote = self.base / "remote.git"
        subprocess.run(["git", "init", "--bare", str(remote)], check=True, capture_output=True)
        self.git("add", "theme.conf")
        self.git("commit", "-m", "initial")
        self.git("remote", "add", "origin", str(remote))
        self.git("push", "-u", "origin", "main")
        (self.repo / "theme.conf").write_text("pink and dark\n")
        with patch.object(cli, "ROOT", self.repo):
            cli.save(type("Args", (), {"message": "theme change", "no_push": False})())
            cli.save(type("Args", (), {"message": None, "no_push": False})())
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.assertEqual(self.git("rev-parse", "HEAD"), self.git("rev-parse", "origin/main"))
        self.assertEqual(self.git("log", "-1", "--format=%s").strip(), "theme change")

    def test_secret_is_rejected_without_echoing_it(self):
        (self.repo / "theme.conf").write_text("ghp_" + "a" * 36)
        self.git("add", "theme.conf")
        with patch.object(cli, "ROOT", self.repo), self.assertRaisesRegex(ValueError, "credential"):
            cli.audit_index()

    def test_nonportable_symlink_is_rejected(self):
        (self.repo / "outside").symlink_to("/tmp/missing-dotfiles-target")
        self.git("add", "outside")
        with patch.object(cli, "ROOT", self.repo), self.assertRaisesRegex(ValueError, "symlink"):
            cli.audit_index()


if __name__ == "__main__":
    unittest.main()
