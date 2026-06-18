describe('Login Screen', () => {

  beforeAll(async () => {
    await device.launchApp();
  });

  it('should show login screen', async () => {
    await expect(element(by.text('Login'))).toBeVisible();
  });

});