const { remote } = require("webdriverio");

async function invalidLoginTest() {

 const driver = await remote({
  hostname: "127.0.0.1",
  port: 4723,
  path: "/",
  capabilities: {
   platformName: "Android",
   "appium:automationName": "UiAutomator2",
   "appium:deviceName": "Android Emulator",
   "appium:app":
   "C:/Users/aliya/Downloads/Semester 5/Mobile Application Development/medicare1/build/app/outputs/flutter-apk/app-debug.apk"
  }
 });

 const emailField =
 await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.EditText[1]');
 await emailField.click();
 await driver.pause(1000);
 await emailField.setValue("wrong@gmail.com");

 const passwordField =
 await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.EditText[2]');
 await passwordField.click();
 await driver.pause(1000);
 await passwordField.setValue("wrong123");

 const login =
 await driver.$('//android.widget.Button[@content-desc="LOGIN"]');

 await login.click();

 await driver.pause(15000);

 console.log("Invalid Login Test Passed");

 await driver.deleteSession();
}

invalidLoginTest();

