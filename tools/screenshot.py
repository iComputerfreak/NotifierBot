from selenium import webdriver
from selenium.webdriver.firefox.options import Options
import sys
import time

# Get the url and name
if len(sys.argv) != 3:
    print("Usage: " + sys.argv[0] + " <File> <URL>")
    sys.exit()

file = sys.argv[1]
url = sys.argv[2]

options = Options()
options.add_argument( "--headless" )
# options.add_argument( "--screenshot test.jpg http://google.com/" )
driver = webdriver.Firefox( firefox_options=options )
driver.get(url)
time.sleep(1)
el = driver.find_element_by_tag_name('body')
el.screenshot(file)
#driver.save_screenshot(file)
# print(driver.title)
# print(driver.current_url)
driver.quit()
sys.exit()
