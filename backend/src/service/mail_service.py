from datetime import datetime

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

    for user in users:
        print(f"Processing user: {user}")
        user_email = user.get("email")
        if "example.com" in user_email:
            print(f"Skipping user {user['_id']} with example.com email: {user_email}")
            continue
        if len(user_email) < 8:
            print(f"Invalid email for user {user['_id']}: {user_email}")
            continue
        if not user_email:
            continue

        # Fetch device data for the user
        devices = user.get("devices", [])

        now = datetime.now()
        # fetch records for the last month
        current_month = now.month
        current_day = now.day
        current_year = now.year

        if current_day == 1:
            # If today is the first day of the month, fetch data for the previous month
            if current_month == 1:
                last_month = 12
                year = now.year - 1
            else:
                last_month = current_month - 1
                year = now.year
        else:
            # If today is not the first day of the month, fetch data for the current month
            last_month = current_month
            year = now.year

        if not devices:
            print(f"No devices found for user {user['_id']}")
            continue

        report_data = []
        for device_id in devices:
            if not device_id:
                print(f"Device ID not found for user {user['_id']}")
                continue

            # Fetch device records for the last month
            device_data = mongo_db[DEVICE_COLLECTION].find_one(
                {"_id": ObjectId(device_id)},
            )

            if not device_data:
                print(f"No records found for device {device_id} of user {user['_id']}")
                continue

            # Filter records for the last month
            filtered_records = [
                record for record in device_data.get("record", [])
                if record["timestamp"][:7] == f"{year}/{last_month:02d}"
            ]

            filtered_water_usage = [
                record for record in device_data.get("water_usage", [])
                if record["date"][:7] == f"{year}/{last_month:02d}"
            ]

            if not filtered_records:
                print(f"No records found for device {device_id} in the last month")
                continue

            report_data.append({
                "device_id": str(device_id),
                "name": device_data.get("name", "Unknown Device"),
                "record": filtered_records,
                "water_usage": filtered_water_usage
            })

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
