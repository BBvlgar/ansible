#!/usr/bin/env python3
# @Author: Alexander Barth
# @Date:   2019-06-05
# @Email:  abarth@it-economics.de
#
from selenium import webdriver
from selenium.webdriver.common.keys import Keys

from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.remote.webelement import WebElement
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from selenium.webdriver.support.ui import Select

import time
import sys

baseURL = "https://www.tm-kundencenter.de"

def WebElement_clearAndType(self, text):
    self.send_keys(1)
    self.clear()
    time.sleep(1)
    self.send_keys(text)
WebElement.clearAndType = WebElement_clearAndType

def login(brower, admin_user, admin_pwd):
    browser.get(baseURL + "/Login.aspx")
    element = WebDriverWait(browser, 60).until(
        EC.presence_of_element_located((By.XPATH, "//input[@id='ctl00_ContentPlaceHolder_Login1_UserName']"))
    )

    browser.find_element_by_id("ctl00_ContentPlaceHolder_Login1_UserName").clearAndType(admin_user)

    browser.find_element_by_id("ctl00_ContentPlaceHolder_Login1_Password").clearAndType(admin_pwd)

    browser.find_element_by_id('ctl00_ContentPlaceHolder_Login1_LoginButton').click()
    time.sleep(20)

    select = Select(browser.find_element_by_id('ctl00_languageSelector'))
    select.select_by_value('de-DE')

    time.sleep(15)


def createUser(browser, lastname, firstname, mail, password):
    browser.get(baseURL + "/ActiveDirectory/AdUser/AdUser_Overview.aspx?ContainerId=69353")

    time.sleep(10)
    
    browser.get(baseURL + "/CommonPages/AddEditUser.aspx?ContainerId=69353&PageType=aduser&PageMode=new")

    username = mail.split('@')[0]
    domain = mail.split('@')[1]

    element = WebDriverWait(browser, 60).until(
        EC.presence_of_element_located((By.ID, "ctl00_ContentPlaceHolder_txtUserName"))
    )

    browser.find_element_by_id("ctl00_ContentPlaceHolder_txtUserName").clearAndType(username)

    # Select Mail Domain
    time.sleep(1)
    browser.find_element_by_xpath("//a[@id='ctl00_ContentPlaceHolder_drpDomain_Arrow']").click()

    element = WebDriverWait(browser, 60).until(
        EC.presence_of_element_located((By.XPATH, "//li[text()='" + domain + "']"))
    )

    browser.find_element_by_xpath("//li[text()='" + domain + "']").click()
    time.sleep(1)

    # Enter User Data
    browser.find_element_by_id("ctl00_ContentPlaceHolder_txtGivenName").clearAndType(firstname)
    browser.find_element_by_id("ctl00_ContentPlaceHolder_txtSurName").clearAndType(lastname)
    browser.find_element_by_id("ctl00_ContentPlaceHolder_txtDisplayName").clearAndType(firstname + " " + lastname)

    browser.find_element_by_id("ctl00_ContentPlaceHolder_txtPassword").clearAndType(password)
    browser.find_element_by_id("ctl00_ContentPlaceHolder_txtPassword2").clearAndType(password)

    # Select Tarif
    browser.find_element_by_xpath("//input[@id='ctl00_ContentPlaceHolder_psOrder_cbPlan_Input']").click()

    element = WebDriverWait(browser, 60).until(
        EC.presence_of_element_located((By.XPATH, "//li[contains(text(),'Office 365 Business Premium')]"))
    )

    browser.find_element_by_xpath("//li[contains(text(),'Office 365 Business Premium')]").click()

    # Select AGB
    element = WebDriverWait(browser, 60).until(
        EC.presence_of_element_located((By.ID, "ctl00_ContentPlaceHolder_psOrder_qhAgreements_ChkAgreement_QHAgreements"))
    )

    if not element.is_selected():
        element.click()

    time.sleep(1)
    element = browser.find_element_by_id("ctl00_ContentPlaceHolder_psOrder_qhAgreements_ChkAgreement_MSAgreements")
    if not element.is_selected():
        element.click()

    time.sleep(2)

    browser.find_element_by_id("ctl00_ContentPlaceHolder_btnSave").click()

    WebDriverWait(browser, 180).until(
        EC.presence_of_element_located((By.ID, "ctl00_ContentPlaceHolder_lblSuccessMessage"))
    )



if sys.argv and len(sys.argv) > 3:
    # browser = webdriver.Firefox()
    browser = webdriver.Remote(command_executor='http://127.0.0.1:4445/wd/hub', desired_capabilities=DesiredCapabilities.FIREFOX)

    lastname    = sys.argv[1]
    firstname   = sys.argv[2]
    mail        = sys.argv[3]
    password    = sys.argv[4]
    admin_user  = "ASM00413\\" + sys.argv[5]
    admin_pwd   = sys.argv[6]
    login(browser, admin_user, admin_pwd)
    createUser(browser, lastname, firstname, mail, password)
    time.sleep(10)
    browser.quit()
else:
    print("execute script with python3 createUser lastname firstname mail password")

