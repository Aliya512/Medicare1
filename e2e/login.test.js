// describe('Login Screen', () => {

//   beforeAll(async () => {
//     await device.launchApp();
//   });

//   it('shows login screen', async () => {
//     await expect(element(by.text('Login'))).toBeVisible();
//   });

//   it('empty email validation', async () => {
//     await element(by.text('Login')).tap();

//     await expect(
//       element(by.text('Please enter email'))
//     ).toBeVisible();
//   });

//   it('empty password validation', async () => {
//     await element(by.id('emailField'))
//       .typeText('test@test.com');

//     await element(by.text('Login')).tap();

//     await expect(
//       element(by.text('Please enter password'))
//     ).toBeVisible();
//   });

// });
describe('Login Screen', () => {

  beforeAll(async () => {
    await device.launchApp();
  });

  it('opens app', async () => {
    await expect(element(by.text('Login'))).toBeVisible();
  });

});