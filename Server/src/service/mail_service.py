from src.config.mongo import mongo_db, DEVICE_COLLECTION, USER_COLLECTION
from src.utils.excel_manager import export_to_excel_devices
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import formatdate
from email import encoders
from email.mime.base import MIMEBase
from src.utils.secrets import SENDER_EMAIL, SENDER_PASSWORD, SMTP_SERVER
from bson import ObjectId


def send_monthly_report() -> None:
    """
    Send a monthly report via email.
    This function should be implemented to gather the necessary data and send the email.

    :return: None
    """
    users = mongo_db[USER_COLLECTION].find()

    print("Starting to send monthly reports...")

    for user in users:
        print(f"Processing user: {user}")
        user_email = user.get("email")
        if len(user_email) < 8:  # Basic validation for email length
            print(f"Invalid email for user {user['_id']}: {user_email}")
            continue
        if not user_email:
            continue

        # Fetch device data for the user
        devices = user.get("devices", [])

        report_data = []
        for device in devices:
            device_data = mongo_db[DEVICE_COLLECTION].find_one({"_id": ObjectId(device)})
            print(f"Processing device: {device} for user {user['_id']}")
            report_data.append(device_data)
        # Export to Excel
        excel_file = export_to_excel_devices(report_data)  # ByteIO object

        if not excel_file:
            print(f"Failed to generate report for user {user['_id']}")
            continue

        msg = MIMEMultipart()
        msg['From'] = SENDER_EMAIL
        msg['To'] = user_email
        msg['Subject'] = 'Monthly Report - Smart Irrigation System'
        msg.attach(MIMEText("Please find attached the monthly report for your devices.", 'plain'))
        msg['Date'] = formatdate(localtime=True)

        part = MIMEBase('application', "octet-stream")
        part.set_payload(excel_file.getvalue())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', 'attachment; filename="monthly_report.xlsx"')
        msg.attach(part)

        print(f"Sending email to {user_email}...")

        try:
            srv = smtplib.SMTP(SMTP_SERVER, 587)
            srv.starttls()  # Secure the connection
            srv.login(SENDER_EMAIL, SENDER_PASSWORD)  # Log in with sender's credentials
            srv.send_message(msg)  # Send the email
            srv.quit()  # Terminate the connection
        except Exception as e:
            print(f"Failed to send email to {user_email}: {e}")
