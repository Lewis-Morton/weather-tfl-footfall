import os
from dotenv import load_dotenv
from datetime import datetime, timedelta
import requests
from pathlib import Path
import time



# 1.
# set up data file = weather_data.csv
# set up state file = last_date.txt
# load api key


base_dir = Path(__file__).resolve().parent
data_file = base_dir / '..' / 'data' / 'raw' / 'weather_data.csv'
data_file = data_file.resolve()

state_file = base_dir / 'last_date.txt'

load_dotenv(base_dir / '..' / '.env')
API_KEY = os.getenv("API_KEY")




# 2.
# set up start/ end dates and chunks (90 days)
# check if this is the first api call i.e state file exists
# if state file exists read its contents and use as current start date else use absolute start date


# absolute project bounds
abs_start_date = '2021-01-01'
abs_end_date = '2025-12-27'

# convert to objects for math
abs_end_date = datetime.strptime(abs_end_date, '%Y-%m-%d')

if os.path.exists(state_file): # last_date.txt
    with open(state_file, "r") as f:
        current_start = f.read().strip()
else:
    current_start = abs_start_date



# 3.
# only write header if state file doesn't exist yet
# set headers to false in api call and manually write headers once/ use sql friendly headers

file_exists = os.path.isfile(data_file)
with open(data_file, 'a') as f:
    if not file_exists or os.path.getsize(data_file) == 0:
        f.write('City,Date,Temp,Humidity,Precip,PrecipProb,Snow,Windspeed,Conditions,Icon\n') #... or whatever the specified data elements are above the api call
    


# 4.

#set counter to track no of calls per day
calls_made_today = 0

while calls_made_today < 10:
    # convert string to object for math
    start_date_obj = datetime.strptime(current_start, '%Y-%m-%d')
    
    # check if we are finished with the whole project
    if start_date_obj >= abs_end_date:
        print('All data retrieved!')
        break

    # calculate end of current 90-day chunk
    end_date_obj = min(start_date_obj + timedelta(days=90), abs_end_date)
    current_end = end_date_obj.strftime('%Y-%m-%d')

    elements = 'name,datetime,temp,humidity,precip,precipprob,snow,windspeed,conditions,icon'
    # call API
    url = f'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/London,UK/{current_start}/{current_end}?key={API_KEY}&contentType=csv&elements={elements}&unitGroup=uk&include=days&options=noheaders'
    
    print(f'Fetching: {current_start} to {current_end}')
    response = requests.get(url)

    if response.status_code == 200:
        response_data = response.text.strip()
        
        # append response data to weather data file
        with open(data_file, 'a') as f:
            f.write(response_data + '\n')
            
        # overwrite state file with new progress date
        with open(state_file, 'w') as f:
            f.write(current_end)

        # prepare for next iteration
        current_start = (end_date_obj + timedelta(days=1)).strftime('%Y-%m-%d')
        calls_made_today += 1
        time.sleep(2) # wait so server doesn't think it's a bot
    else:
        print(f'Error: {response.status_code}')
        break # stop to save daily credits

print(f'Done for today. Made {calls_made_today} calls.')
