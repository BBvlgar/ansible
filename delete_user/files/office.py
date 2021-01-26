#!/usr/bin/env python3
# @Author: Alexander Barth and Lisa Pohl
# @Date:   2020-11-14
# @Email:  abarth@it-economics.de and lpohl@it-economics.de
#
import argparse as argparse
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys

from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.remote.webelement import WebElement
import time

import configparser

parser = argparse.ArgumentParser()
parser.add_argument('-m', type=str, nargs='?', help='Method')
parser.add_argument('-c', type=str, nargs='?', help='Code')
parser.add_argument('-au', type=str, nargs='?', help='Admin Office User')
parser.add_argument('-ap', type=str, nargs='?', help='Admin Office Password')
parser.add_argument('-up', type=str, nargs='?', help='User Office Password to be set')
parser.add_argument('-u', type=str, nargs='?', help='Office User')
args = parser.parse_args()

browser = webdriver.Remote(command_executor='http://127.0.0.1:4446/wd/hub', desired_capabilities=DesiredCapabilities.FIREFOX)

def WebElement_clearAndType(self, text):
    self.send_keys(1)
    self.clear()
    time.sleep(1)
    self.send_keys(text)
WebElement.clearAndType = WebElement_clearAndType

def disable2FA():
    browser.get("https://account.activedirectory.microsoftazure.de/usermanagement/multifactorverification.aspx")
    time.sleep(20)
    browser.find_element_by_id('UserListGrid_SearchButton').click()

    time.sleep(10)
    browser.find_element_by_id('UserListGrid_SearchTextBox').clearAndType(args.u)
    browser.find_element_by_id('UserListGrid_SearchTextBox').send_keys(Keys.RETURN)
    time.sleep(2)

    browser.find_element_by_xpath("//table/tbody/tr[2]/td[1]/input").click()
    time.sleep(2)

    browser.find_element_by_id('DisableMultifactorVerification').click()
    element = WebDriverWait(browser, 60).until(
                EC.presence_of_element_located((By.XPATH, "//*[text()='Disable multi-factor authentication?']"))
            )

    browser.find_element_by_id('RemoveFromPolicyButtonYes').click()

    time.sleep(20)

def changePassword():
    browser.get("https://portal.office.de/adminportal")

    element = WebDriverWait(browser, 60).until(
                EC.presence_of_element_located((By.XPATH, "//*[text()='Microsoft 365 admin center']"))
            )

    browser.find_element_by_xpath("//input[@id='modernSearchTextBoxId']").clearAndType(args.u)
    time.sleep(6)
    browser.find_element_by_xpath("//ul[@id='searchResultsInfo']/li[1]").click()
    time.sleep(6)
    browser.find_element_by_id('ResetPassword').click()

    time.sleep(6)
    browser.find_element_by_xpath("//input[@id='selfgenerate']").click()
    browser.find_element_by_xpath("//input[@id='newpassword2']").clearAndType(args.up)
    browser.find_element_by_xpath("//input[@id='requirePasswordChange']").click()
    browser.find_element_by_id('ResetUserPasswordSubmit').click()


try:
    browser.get("https://office.de")
    browser.find_element_by_xpath("//input[@name='loginfmt']").clearAndType(args.au)
    browser.find_element_by_xpath("//input[@id='idSIButton9']").click()

    time.sleep(2)
    browser.find_element_by_xpath("//input[@name='passwd']").clearAndType(args.ap)
    browser.find_element_by_xpath("//input[@id='idSIButton9']").click()

    print("Wait for 2FA")
    time.sleep(2)

    if ("Enter code" in browser.page_source) and args.m == "Code":
        browser.find_element_by_xpath("//*[@id='idTxtBx_SAOTCC_OTC']").clearAndType(args.c)
        browser.find_element_by_xpath("//*[@id='idSubmit_SAOTCC_Continue']").click()
    else:
        print('no code')

    time.sleep(20)
    element = WebDriverWait(browser, 60).until(
    	EC.presence_of_element_located((By.XPATH, "//*[text()='Stay signed in?']"))
      )

    browser.find_element_by_xpath("//input[@id='idBtn_Back']").click()

except Exception as e:
    raise Exception("Could not login to Office, please check your saved credentials.")

# Disable 2FA of user
try:
    disable2FA()
except Exception as e:
    pass
time.sleep(20)

# change password of user
changePassword()

time.sleep(20)
browser.quit()
