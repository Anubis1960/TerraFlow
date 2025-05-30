from apscheduler.schedulers.background import BackgroundScheduler
from src.service.mail_service import send_monthly_report
import atexit


def start_scheduler():
    scheduler = BackgroundScheduler()
    scheduler.add_job(
        func=lambda: send_monthly_report(),
        trigger='cron',
        day='last',  # Run on the last day of the month
        hour=0,  # At midnight
    )
    print("Scheduler started")
    scheduler.start()

    print("Job added to scheduler")

    atexit.register(lambda: scheduler.shutdown())

    print("Scheduler shutdown registered")
