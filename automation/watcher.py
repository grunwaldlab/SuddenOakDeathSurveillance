import os
import sys
import argparse
import shelve
import configparser
import pathlib
import hashlib


class CaseConfigParser(configparser.ConfigParser):
    """ Class to override the case-insensitive ConfigParser """
    def optionxform(self, optionstr):
        return optionstr


def timestamp(pathname):
    """ Return the current timestamp as specified by the os """
    return pathname.lstat().st_mtime


def checksum(pathname):
    """ Return the md5 checksum for a given file """
    # Open file for reading in binary mode
    with open(pathname, "rb") as f:
        # Create md5 hash to update
        file_hash = hashlib.md5()

        # Iteratively grab the next chunk of the file and update hash
        while chunk := f.read(8192):
            file_hash.update(chunk)

        # Digest into hexadecimal and return
        return file_hash.hexdigest()


def updatedb(db, pathname):
    """ Update timestamp, checksum and return True if either has changed """
    # Initialize entry in database if not present already
    name = str(pathname)
    if name not in db:
        db[name] = {}
        db[name]["timestamp"] = None
        db[name]["checksum"] = None

    # Check if it doesn't exist in operating system
    if not pathname.exists():
        # Doesn't exist so return False
        return False

    # Check if the file / directory timestamp has changed
    current_timestamp = timestamp(pathname)
    if current_timestamp == db[name]["timestamp"]:
        # Not modified so return False
        return False

    # Split on file or directory
    if pathname.is_file():
        # Get checksum and check against previous
        current_checksum = checksum(pathname)
        if current_checksum == db[name]["checksum"]:
            # Not modified so return False
            return False

        # Update details and return True
        db[name]["timestamp"] = current_timestamp
        db[name]["checksum"] = current_checksum
        return True
    else:
        # Directory, so just update details and return True
        db[name]["timestamp"] = current_timestamp
        return True


def init(args):
    # Initialize new config file
    config = CaseConfigParser(allow_no_value=True)

    # Base settings
    config["Settings"] = {}
    config["Settings"]["Database"] = args.database
    config["Settings"]["Recursive"] = str(args.recursive)
    config["Settings"]["Worker"] = args.worker

    # Add files and directories to watch list
    config["WatchList"] = {}
    for name in args.watchlist:
        filepath = pathlib.Path(name).resolve()
        config["WatchList"][str(filepath)] = None

    # Write config file
    with open(args.config, "w") as configfile:
        config.write(configfile)


def run(args):
    # Run watcher based on config file
    config = CaseConfigParser(allow_no_value=True)
    config.read(args.config)

    # Open shelve database and search for files which have changed
    modified = []
    with shelve.open(config["Settings"]["Database"], writeback=True) as db:
        # Check for changes to watched files and directories
        for name in config["WatchList"]:
            # Get pathname for this file / directory
            pathname = pathlib.Path(name)

            # Split on files / directories
            if pathname.is_file():
                # Check if file has changed on disk
                has_changed = updatedb(db, pathname)
                if has_changed:
                    modified.append(pathname)
            else:
                # Get list of subfiles in this directory
                subfiles = []
                if config["Settings"].getboolean("Recursive"):
                    # Recursive
                    subfiles = [x for x in pathname.glob("**/*")]
                else:
                    # Non recursive
                    subfiles = [x for x in pathname.iterdir()]

                # Filter out directories, hidded files, and '.db' files
                subfiles = [p for p in subfiles if p.is_file()]
                subfiles = [p for p in subfiles if not p.name.startswith('.')]
                subfiles = [p for p in subfiles if not p.name.endswith(".db")]

                # Iterate through subfiles and check if any have changed
                for pathname in subfiles:
                    has_changed = updatedb(db, pathname)
                    if has_changed:
                        modified.append(pathname)

    # Print modified files
    for pathname in modified:
        print(f"Modified: {pathname}")

    # Call worker script
    modified = ' '.join([str(x) for x in modified])
    command = f"{config['Settings']['Worker']} {modified}"
    exit_code = os.system(command)
    if exit_code != 0:
        print(f"\'{command}\' returned with exit code: {exit_code}")


if __name__ == "__main__":
    # Parse command line args
    parser = argparse.ArgumentParser(
            description="Watch a directory and report changes to a worker",
            prog="watcher")
    parser.add_argument(
            "mode",
            type=str,
            choices=["init", "run"],
            help="Initialize or run a watcher instance")
    parser.add_argument(
            "-c",
            "--config",
            type=str,
            default="watcher.config",
            help="Watcher config file (default 'watcher.config')")
    parser.add_argument(
            "-d",
            "--database",
            type=str,
            default="watcher.db",
            help="Database file to track changes (default 'watcher.db')")
    parser.add_argument(
            "-w",
            "--worker",
            type=str,
            default="echo",
            help="Worker script to call on files (default 'echo')")
    parser.add_argument(
            "-r",
            "--recursive",
            action="store_true",
            help="Recursively check sub-directories for changes")
    parser.add_argument(
            "watchlist",
            type=str,
            nargs="*",
            help="List of files and directories to watch")
    args = parser.parse_args(sys.argv[1:])

    # Switch on mode
    if args.mode == "init":
        init(args)
    else:
        run(args)
