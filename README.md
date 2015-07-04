# Pugs!
## A pug tracker.

Features:
- Scrollable set of pugs:
  - Shows different image of a pug retrieved from pugme.herokuapp.com.
  - Shows name of pug.
  - Shows weight of pug.
  - Shows temperament of pug.
- Creates default data set w/ 4 pugs.
- Saves all pugs to Core Data and persists upon relaunch.
- Can create a pug w/ custom data.
  - Makes sure that pug weight is between 13 and 20 pounds.
- Can delete a pug (long press the cell)
- If pug weight goes below 10 pounds, pug perishes due to malnutrition.
- If pug weight goes above 20 pounds, pug becomes sedentary.
- Feeding pug increases weight by 0.5 pounds.
- Walking pug decreases weight by 0.25 pounds

UI tested on iPhone 4S, 5, 6 and 6 Plus.

I did my best to comment as much of the code as I could, but if there any questions, or any features/testing that you want me to add I'll be happy to do so!

Code Challenge Instructions
=====================
#pugTracker

##Objective

Track all of the pugs and their activity.


##Summary

Create an application that displays a scrollable set of "pug cards" in a UIViewController, each displaying a different image of a pug, and overlayed on top of the pug image, a set of statistics about the pug (its name, its weight, and a short description about its temperament.) [For the sake of time, you may create just four sample pugs to display upon the initial opening of the application, such that you don't have to spend more than 10 minutes creating a dataset.] All pugs should have an initial weight of between 13 and 20 pounds. 

You may use the following API to get random pug images: http://pugme.herokuapp.com/random. (In other words, build an API client that will pull random images from this API every time you run the app for your four sample pugs, and any additional pugs added. See below. While the images should change, the names and details of the sample pugs may remain static.)

Statistics and the chosen images for each pug should persist in Core Data such that once a pug is created, its image and statistics are not going to randomly change upon the next app open, and also should persist if the app is closed.

It should be possible for a user to add a new pug to the set of pugs in the dataset via a second view controller that takes inputs for the pug's name, its weight (within the reasonable range only), and its temperament (free text).

Finally, the user should be able to feed the pug chosen via a `Feed Me` button on each "pug card". Each time the button is pressed, the pug will increase in weight by 0.5 pounds. The user should also be able to take the pug for a walk via a `Walk me` button on the "pug card".  Each time this button is pressed, the weight of the dog will decrease by 0.25 pounds. If the weight of the pug increases to more than 20 pounds, the temperament of the pug should change to "Sedentary. Spends its days watching TV on the couch." If the total weight of the pug goes below ten pounds, the card should "gray out" altogether and show a label over it that says that the dog has perished due to malnutrition. If the weight of the pug is between 10 and 20 pounds, its temperament should be whatever the user had originally entered as that pug's temperament. 


##Tips

Remember: Make it work, make it right, make it fast! We'd prefer to see a working version of this app than a perfectly coded one. So make it work first. Then go back and clean up your code with the time you have remaining and make it elegant. If you still have time, find ways to make it more performant.
