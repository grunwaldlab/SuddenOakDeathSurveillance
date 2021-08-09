import subprocess
from email.mime.text import MIMEText


sendmail = "/sbin/sendmail"


def sendEmail(from_address, to_address, subject, body):
    # Create email message
    msg = MIMEText(body)
    msg['From'] = from_address
    msg['To'] = to_address
    msg['Subject'] = subject

    # Send using subprocess
    # -t = look for recipients in 'To'
    # -oi = ignore single '.' in message which normally marks end
    subprocess.run([sendmail, "-t", "-oi"], input=msg.as_bytes())


if __name__ == "__main__":
    from_address = "andrew.s.tupper@gmail.com"
    to_address = "andrew.tupper@oregonstate.edu"
    subject = "test"
    sendEmail(from_address, to_address, subject, "blah")
