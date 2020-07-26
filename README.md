# NSSentryGun

An iOS-powered Sentry Gun from Team Fortress 2.

![TF2](https://wiki.teamfortress.com/w/images/thumb/e/ee/Engywithsg.png/350px-Engywithsg.png)

## Summary

iOS uses CoreML to detect people's faces. Angles are calculated and sent to a Raspberry Pi via socket connection, which sends the angles to a connected Arduino's serial port which controls 3 servos (X axis, Y axis and a projectile pusher) and 2 DC motors (to boost the pushed projectiles)

## Instructions

Things you need to do to run this:

- Change the socket IP address at the iOS project / Raspberry python file to match your Raspberry's IP
- Change the USB port at the Raspberry's python file to match your Arduino's
