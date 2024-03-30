from selenium import webdriver
from selenium.webdriver.firefox.options import Options
import os

# Your Grafana URL and cookie value
grafana_url = os.getenv('grafana_url')
cookie_value = os.getenv('grafana_cookie_value')
cookie_name = 'grafana_session'

# Set up the Firefox options (headless mode optional)
options = Options()
options.headless = True

# Create a new Firefox session
driver = webdriver.Firefox()
driver.get(grafana_url)

# Add the cookie
driver.add_cookie({'name': cookie_name, 'value': cookie_value})

# Refresh the page to apply the cookie
driver.refresh()

# Close the browser when done
driver.quit()

