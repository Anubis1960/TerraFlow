import pandas as pd
from openpyxl import Workbook
from openpyxl.chart import LineChart, BarChart, Reference
from openpyxl.chart.axis import ChartLines
from openpyxl.utils.dataframe import dataframe_to_rows
from openpyxl.styles import PatternFill, Font, GradientFill
from openpyxl.drawing.fill import GradientFillProperties, GradientStop

# Sample data structure
data = {
    "record": [
        {
            "sensor_data": {
                "soil_moisture": 45,
                "air_humidity": 60,
                "air_temperature": 25
            },
            "timestamp": "2023/10/01 12:00:00"
        },
        {
            "sensor_data": {
                "soil_moisture": 50,
                "air_humidity": 65,
                "air_temperature": 26
            },
            "timestamp": "2023/10/02 12:00:00"
        },
        {
            "sensor_data": {
                "soil_moisture": 55,
                "air_humidity": 70,
                "air_temperature": 27
            },
            "timestamp": "2023/10/03 12:00:00"
        },
        {
            "sensor_data": {
                "soil_moisture": 60,
                "air_humidity": 75,
                "air_temperature": 28
            },
            "timestamp": "2023/11/01 12:00:00"
        },
        {
            "sensor_data": {
                "soil_moisture": 65,
                "air_humidity": 80,
                "air_temperature": 29
            },
            "timestamp": "2023/11/02 12:00:00"
        }
    ],
    "water_usage": [
        {
            "water_used": 100,
            "date": "2023/10"
        },
        {
            "water_used": 120,
            "date": "2023/11"
        },
        {
            "water_used": 90,
            "date": "2023/12"
        }
    ]
}


def create_line_chart(ws, df, title, y_axis_title, x_axis_title, start_col, start_row):
    """Create a styled line chart and add it to the worksheet."""
    line_chart = LineChart()
    line_chart.title = title
    line_chart.style = 13
    line_chart.y_axis.title = y_axis_title
    line_chart.x_axis.title = x_axis_title

    # Add data to the chart
    data = Reference(ws, min_col=2, min_row=2, max_row=len(df) + 1, max_col=4)
    categories = Reference(ws, min_col=1, min_row=2, max_row=len(df) + 1)
    line_chart.add_data(data, titles_from_data=True)
    line_chart.set_categories(categories)

    # Style the chart
    line_chart.y_axis.majorGridlines = ChartLines()  # Use ChartLines for gridlines
    line_chart.x_axis.majorGridlines = ChartLines()  # Use ChartLines for gridlines
    line_chart.legend.position = "b"

    # Add gradient fill to the chart area
    gradient_fill = GradientFill()

    ws.add_chart(line_chart, f"{start_col}{start_row}")


def create_bar_chart(ws, df, title, y_axis_title, x_axis_title, start_col, start_row):
    """Create a styled bar chart and add it to the worksheet."""
    bar_chart = BarChart()
    bar_chart.title = title
    bar_chart.style = 10
    bar_chart.y_axis.title = y_axis_title
    bar_chart.x_axis.title = x_axis_title

    # Add data to the chart
    data = Reference(ws, min_col=2, min_row=2, max_row=len(df) + 1, max_col=2)
    categories = Reference(ws, min_col=1, min_row=2, max_row=len(df) + 1)
    bar_chart.add_data(data, titles_from_data=True)
    bar_chart.set_categories(categories)

    # Style the chart
    bar_chart.y_axis.majorGridlines = ChartLines()  # Use ChartLines for gridlines
    bar_chart.x_axis.majorGridlines = ChartLines()  # Use ChartLines for gridlines
    bar_chart.legend.position = "b"

    ws.add_chart(bar_chart, f"{start_col}{start_row}")

def export_to_excel(data, filename="exported_data.xlsx"):
    # Process sensor records
    records = data["record"]
    sensor_data_list = []
    for record in records:
        sensor_data = record["sensor_data"]
        timestamp = record["timestamp"]
        sensor_data_list.append({
            "Timestamp": timestamp,
            "Soil Moisture": sensor_data["soil_moisture"],
            "Air Humidity": sensor_data["air_humidity"],
            "Air Temperature": sensor_data["air_temperature"]
        })

    # Create a DataFrame for sensor data
    sensor_df = pd.DataFrame(sensor_data_list)

    # Convert the Timestamp column to datetime with the correct format
    try:
        sensor_df["Timestamp"] = pd.to_datetime(sensor_df["Timestamp"], format="%Y/%m/%d %H:%M:%S")
    except ValueError as e:
        print(f"Error parsing timestamp: {e}")
        return

    sensor_df["Month"] = sensor_df["Timestamp"].dt.to_period("M")

    # Process water usage data
    water_usage_list = []
    for usage in data["water_usage"]:
        water_usage_list.append({
            "Date": usage["date"],
            "Water Used": usage["water_used"]
        })

    # Create a DataFrame for water usage
    water_usage_df = pd.DataFrame(water_usage_list)

    # Create an Excel workbook and sheets
    wb = Workbook()
    ws_sensor = wb.active
    ws_sensor.title = "All Sensor Data"
    ws_water = wb.create_sheet("Water Usage")

    # Write sensor data to the "All Sensor Data" sheet
    for row in dataframe_to_rows(sensor_df.drop(columns=["Month"]), index=False, header=True):
        ws_sensor.append(row)

    # Write water usage data to the "Water Usage" sheet
    for row in dataframe_to_rows(water_usage_df, index=False, header=True):
        ws_water.append(row)

    # Add a line chart for all sensor data
    create_line_chart(ws_sensor, sensor_df, "Sensor Data Over Time", "Values", "Timestamp", "F", 2)

    # Add a bar chart for water usage
    create_bar_chart(ws_water, water_usage_df, "Monthly Water Usage", "Water Used", "Date", "E", 2)

    # Create separate sheets and graphs for each month
    for month, month_data in sensor_df.groupby("Month"):
        month_str = month.strftime("%Y-%m")
        ws_month = wb.create_sheet(month_str)

        # Write month data to the sheet
        for row in dataframe_to_rows(month_data.drop(columns=["Month"]), index=False, header=True):
            ws_month.append(row)

        # Add a line chart for the month's sensor data
        create_line_chart(ws_month, month_data, f"Sensor Data for {month_str}", "Values", "Timestamp", "F", 2)

    # Save the workbook
    wb.save(filename)
    print(f"Data exported to {filename} successfully!")

if __name__ == "__main__":
    export_to_excel(data)