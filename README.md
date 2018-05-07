# NSSentryGun

An iOS-powered crowd control machine. Requires an iOS device, a Raspberry Pi and an Arduino.

https://twitter.com/rockthebruno/status/993152346841669632

## Summary

iOS uses CoreML to detect people's faces. Angles are calculated and sent to a Raspberry Pi via socket connection, which routes the angles to an Arduino which controls the sentry's motors. A button connected to the Raspberry is used to turn the whole thing on and off.

## Instructions

The whole thing is currently just a prototype, with the Arduino only handling a single servo motor that moves in the X axis. I'll update this README as the project progresses.

Things you need to do to run this:

- Change the socket IP address at the iOS project / Raspberry python file to match your Raspberry's IP
- Change the USB port at the Raspberry's python file to match your Arduino's
- Change the pins at the Arduino file to match your actual build (Current: servo at pin 9 and buzzer at pin 11)
- The Raspberry listens to commands from a Dream Cheeky Big Red Button: https://www.amazon.com/Dream-Cheeky-902-Electronic-Reference/dp/B004D18MCK/ref=cm_cr_arp_d_product_top?ie=UTF8 . You might want to edit the Raspberry's python file to stop this interaction if you do not want to use this button.

## Interacting with the Sentry Gun:

TODO

## TODO

- [ ] Arduino: Add an Y axis servo, a trigger-pulling servo, and a Nerf gun
- [ ] iOS/Raspberry: Change socket connection to a bluetooth connection

## Thanks

I borrowed some AVCaptureVideoPreviewLayer code from [https://github.com/Weijay/AppleFaceDetection](Weijay). Thanks!
