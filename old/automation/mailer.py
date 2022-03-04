#! /bin/env python3
import sys
import argparse
import configparser
import subprocess
from email.mime.text import MIMEText


class CaseConfigParser(configparser.ConfigParser):
    """ Class to override the case-insensitive ConfigParser """
    def optionxform(self, optionstr):
        return optionstr


def init(args):
    """ Initialize a new config file """
    # Initialize new config file
    config = CaseConfigParser()

    # Base settings
    config["Settings"] = {}
    config["Settings"]["Path"] = args.path

    # Email Settings
    config["Email"] = {}
    config["Email"]["From"] = args.from_address
    config["Email"]["To"] = ','.join(args.to_address)
    config["Email"]["Subject"] = args.subject

    # Write config file
    with open(args.config, "w") as configfile:
        config.write(configfile)


def run(args):
    """ Run the Mailer program, sending body args """
    # Run mailer based on config file
    config = CaseConfigParser()
    config.read(args.config)

    # Create email message
    msg = MIMEText(args.body)
    msg['From'] = config["Email"]["From"]
    msg['To'] = config["Email"]["To"]
    msg['Subject'] = config["Email"]["Subject"]

    # Send using subprocess
    # -t = look for recipients in 'To'
    # -oi = ignore single '.' in message which normally marks end
    print(msg.as_string())
    sendmail = config["Settings"]["Path"]
    result = subprocess.run([sendmail, "-t", "-oi"], input=msg.as_bytes())
    if result.returncode != 0:
        print(f"\'{sendmail}\' returned with exit code: {result.returncode}")


if __name__ == "__main__":
    # Parse command line args
    parser = argparse.ArgumentParser(
            description="Program to send automated email messages",
            prog="mailer")
    parser.add_argument(
            "mode",
            type=str,
            choices=["init", "run"],
            help="Initialize or run a mailer instance")
    parser.add_argument(
            "-c",
            "--config",
            type=str,
            default="mailer.config",
            help="Mailer config file (default 'mailer.config')")
    parser.add_argument(
            "-f",
            "--from-address",
            type=str,
            help="From address for email message")
    parser.add_argument(
            "-t",
            "--to-address",
            type=str,
            nargs="+",
            help="To address(es) for email message")
    parser.add_argument(
            "-s",
            "--subject",
            type=str,
            default="Mailer test",
            help="Subject for email message")
    parser.add_argument(
            "-p",
            "--path",
            type=str,
            default="/sbin/sendmail",
            help="Path to sendmail")
    parser.add_argument(
            "body",
            type=str,
            nargs="?",
            help="Body of message to send")
    args = parser.parse_args(sys.argv[1:])

    # Switch on mode
    if args.mode == "init":
        init(args)
    else:
        run(args)
