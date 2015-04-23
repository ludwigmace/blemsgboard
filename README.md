BLE Message Board
==========
Robert Sandoval and Mason Schoolfield developed a local peer to peer message board for iOS using Bluetooth Low Energy as a transport mechanism.  This is the code for the SubContext project for Dr. Christine Julien's Mobile Computing at the University of Texas at Austin in Spring 2014.

This project was developed for iOS 7 (on an iPhone 4S or above, or any iOS device that supports Bluetooth 4).

Users can just show up and start a message board.  As long as people are talking about the same thing (ie same topic/tag/subject/whatever) and there's enough folks around you end up with a level of persistence.

The topic name goes in the box on the upper left.  The name field is parsed from the "User's iPhone" device name.  By default only the last 5 minutes of messages are pulled; this is changeable via a global variable.

Message propagation isn't immediate as the app cycles between Central and Peripheral modes.  Now that Android's Bluetooth stack is more feature-rich and reliable (mid 2015) this app could be extended to Android.
