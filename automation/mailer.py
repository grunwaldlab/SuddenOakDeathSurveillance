import subprocess
from email.mime.text import MIMEText


sendmail = "/usr/sbin/sendmail"


def sendEmail(from_address, to_address, subject, body):
    msg = MIMEText(body)
    msg['From'] = from_address
    msg['To'] = to_address
    msg['Subject'] = subject

    subprocess.run([sendmail, "-t", "-oi"], input=msg.as_bytes())