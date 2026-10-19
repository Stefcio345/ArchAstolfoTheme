#!/usr/bin/env python3

import gi
gi.require_version("Playerctl", "2.0")

from gi.repository import Playerctl, GLib
from gi.repository.Playerctl import Player

import argparse
import json
import logging
import os
import signal
import sys
from typing import List

logger = logging.getLogger(__name__)


def signal_handler(sig, frame):
    logger.info("Received signal to stop, exiting")
    sys.stdout.write("\n")
    sys.stdout.flush()
    sys.exit(0)


class PlayerManager:
    def __init__(self, selected_player=None, excluded_player=""):
        self.manager = Playerctl.PlayerManager()
        self.loop = GLib.MainLoop()

        self.manager.connect("name-appeared", self.on_player_appeared)
        self.manager.connect("player-vanished", self.on_player_vanished)

        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)

        self.selected_player = selected_player
        self.excluded_player = excluded_player.split(",") if excluded_player else []

        self.init_players()

    def init_players(self):
        for player in self.manager.props.player_names:
            if player.name in self.excluded_player:
                continue
            if self.selected_player is not None and self.selected_player != player.name:
                logger.debug("%s is not the filtered player, skipping it", player.name)
                continue
            self.init_player(player)

    def run(self):
        logger.info("Starting main loop")
        self.loop.run()

    def init_player(self, player):
        logger.info("Initialize new player: %s", player.name)
        player = Player.new_from_name(player)
        player.connect("playback-status", self.on_playback_status_changed, None)
        player.connect("metadata", self.on_metadata_changed, None)
        self.manager.manage_player(player)
        self.on_metadata_changed(player, player.props.metadata)

    def get_players(self) -> List[Player]:
        return self.manager.props.players

    def write_output(self, text, player, extra_classes=None):
        logger.debug("Writing output: %s", text)

        classes = ["custom-" + player.props.player_name]
        if extra_classes:
            if isinstance(extra_classes, str):
                classes.append(extra_classes)
            else:
                classes.extend(extra_classes)

        output = {
            "text": text,
            "class": classes,
            "alt": player.props.player_name,
        }

        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

    def clear_output(self):
        output = {
            "text": "",
            "class": ["hidden"],
            "alt": "",
        }
        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

    def on_playback_status_changed(self, player, status, _=None):
        logger.debug(
            "Playback status changed for player %s: %s",
            player.props.player_name,
            status,
        )
        self.on_metadata_changed(player, player.props.metadata)

    def get_first_playing_player(self):
        players = self.get_players()
        logger.debug("Getting first playing player from %d players", len(players))

        if len(players) > 0:
            for player in players[::-1]:
                if player.props.status == "Playing":
                    return player
            return players[0]

        logger.debug("No players found")
        return None

    def show_most_important_player(self):
        logger.debug("Showing most important player")
        current_player = self.get_first_playing_player()
        if current_player is not None:
            self.on_metadata_changed(current_player, current_player.props.metadata)
        else:
            self.clear_output()

    def build_track_info(self, player, metadata):
        player_name = player.props.player_name
        artist = player.get_artist()
        title = player.get_title()

        if artist is not None:
            artist = artist.replace("&", "&amp;")
        if title is not None:
            title = title.replace("&", "&amp;")

        if (
            player_name == "spotify"
            and "mpris:trackid" in metadata.keys()
            and ":ad:" in str(metadata["mpris:trackid"])
        ):
            return ""

        if artist and title:
            return f"{artist} - {title}"
        if title:
            return title

        return ""

    def on_metadata_changed(self, player, metadata, _=None):
        logger.debug("Metadata changed for player %s", player.props.player_name)

        current_playing = self.get_first_playing_player()
        if current_playing is not None and current_playing.props.player_name != player.props.player_name:
            logger.debug(
                "Other player %s is playing, skipping",
                current_playing.props.player_name,
            )
            return

        track_info = self.build_track_info(player, metadata)

        if not track_info:
            self.clear_output()
            return

        if player.props.status == "Playing":
            track_info = " " + track_info
        else:
            track_info = " " + track_info

        self.write_output(track_info, player)

    def on_player_appeared(self, _, player):
        logger.info("Player has appeared: %s", player.name)

        if player.name in self.excluded_player:
            logger.debug("New player appeared, but it's in exclude list, skipping")
            return

        if player is not None and (self.selected_player is None or player.name == self.selected_player):
            self.init_player(player)
        else:
            logger.debug("New player appeared, but it's not the selected player, skipping")

    def on_player_vanished(self, _, player):
        logger.info("Player %s has vanished", player.props.player_name)
        self.show_most_important_player()


def parse_arguments():
    parser = argparse.ArgumentParser()

    parser.add_argument("-v", "--verbose", action="count", default=0)
    parser.add_argument("-x", "--exclude", help="Comma-separated list of excluded players")
    parser.add_argument("--player")
    parser.add_argument("--enable-logging", action="store_true")

    return parser.parse_args()


def main():
    arguments = parse_arguments()

    if arguments.enable_logging:
        logfile = os.path.join(
            os.path.dirname(os.path.realpath(__file__)),
            "media-player.log",
        )
        logging.basicConfig(
            filename=logfile,
            level=logging.DEBUG,
            format="%(asctime)s %(name)s %(levelname)s:%(lineno)d %(message)s",
        )

    logger.setLevel(max((3 - arguments.verbose) * 10, 0))

    logger.info("Creating player manager")
    if arguments.player:
        logger.info("Filtering for player: %s", arguments.player)
    if arguments.exclude:
        logger.info("Exclude player(s): %s", arguments.exclude)

    player = PlayerManager(arguments.player, arguments.exclude)
    player.run()


if __name__ == "__main__":
    main()
