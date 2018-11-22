---
layout: post
title: "The four musketeers - The cat-mouse game and lessons learned"
date: "2017-12-11"
author: "Zeshan Anwar"
---



![](https://media.giphy.com/media/fxeeuml8GaESfmuE4z/giphy.gif)

In early 2015, my brother and our two best friends decide to start an app-development agency. We name it `BearStacks Development`. All of us are in school at the time, and ‘co-founder' seems like a good thing to put on our resumes. After we barely cover the $99 developer fee; we decide to brainstorm for ideas. Unlike all first-time app developers, we decide on a game. 

We term it Memory Swipe.  It was my brothers idea: show a pattern on the screen and ask the player to mimic it. If the redrawing was close enough, the player would win the round and progress to a harder level. The game was designed with no end so a player could potentially play forever.

Development took place over a several semesters - in-between lectures, missed assignments, botched midterms and exams. We were making slow and steady progress. The coolest part of the app was the algorithm we devised to calculate how close a redrawing was to the original.

One early morning, before leaving for our 8:30 am classes (damn UWaterloo) one of us enters the name "Memory Swipe" into the App Store search bar and presses enter. It was a mindless search, made without the expectation of seeing anything but it did. There was an app on the App Store with our name on it. Not only was the name the same, but the icon, company logo, screenshots were all the same. Everything was exactly as we had designed it.

There was one slight problem though - none of us had uploaded it to the App store. Apple has a pretty involved app submission process and it's not something you can accidentally fat-finger from your IDE. Initially, we think that one of us went ahead with the submission but in a span of 15 mins and several frantic WhatApp messages, it became pretty clear that someone had stolen our code.

We had made our first mistake. Being first-time iOS developers, we thought it 'wise' to push to a public repo on GitHub. We were naive and thought who would steal our crappy code. Why dish out money for a private repo when a public one suffices.

We check the dates, and the game has been on the app store for about a month now. It also has one update - `V1.1 Some bug fix`. Whoever was stealing our code was also keeping it up to date will all our recent updates to GitHub. They had the audacity to include the message `Some bug fix` without having an inkling as to what was being fixed. After fuming for a few hours, we decide to investigate who this was. 

We check our GitHub repo to see who else has forked our code. We see that several people have forked our code but none of them looked like our thief. Some of them didn't have Apple developer accounts in the same name, and the ones that did, didn't have our app posted. 

After some further investigation, and some digging through the web, we chance upon our thief. A developer account linked to somebody half-way around the world. Our `thief` has hundreds of well-designed iOS apps to their name. Their apps look completely legit with reviews and comments. They have a phone number, address and different ways to contact them. To the world, this seems like a completely legit operation.

We send emails to that person to take down the app, and even have the courage to call them (not worried about money now). We received emails back in a foreign language which we literally put into Google Translate to understand. They deny everything and want us to show proof that we wrote the code.

When looking at the code again we realized one simple fact - `Xcode`, by default copyright header at the top of every file with the name of the developer and the year. We immediately send back an email mentioning that EVERY SINGLE FILE has a copyright header with one of our four names. This scares them, and we don't hear back for a few weeks.

We get in touch with Apple, and relay the situation to them. In the meantime, we hastily submit our app for review and it gets rejected for having the word 'Memory'. Apparently that word is copyright in some European countries as it clashes with a board game. We remove the space (MemorySwipe) and put it up for review again. This time it fails because it matches another app on the store - our thief's. We file a petition to Apple, mention the headers, and after a month they take down our thief's app.

**Lessons learned:** 

1. Never push private code to a public repo. If pushed, assume it has been compromised.
2. Those annoying default copyright headers are useful.
3. Don't cheap out over security or anonymity.















[bearstacks-apps]: https://itunes.apple.com/us/developer/bearstacks-development/id1108705924