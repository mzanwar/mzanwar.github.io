---
layout: post
title: "The four musketeers - The cat-mouse game and lesson learned"
date: "2017-12-11"
author: "Zeshan Anwar"
---

In early 2015, my brother and our two best friends (who are also brothers) decide to start an app-development agency. We name it `BearStacks Development`. All of us are in school at the time, and 'Co-founder' seems like a good thing to put on our resumes. After we barely cover the $99 developer fee; we decide to brainstorm for ideas. Much like all first-time app developers, we decide on a game. 

We name it Memory Swipe.  It was my brothers idea: show a pattern on the screen and ask the player to mimic it. If the redrawing was close enough, the player would progress to a harder level. The game was designed with no end so a player could potentially play forever.

Now this development took place over a few semesters - in-between lectures, assignments, midterms and exams. One fateful morning, before our 8:30am classes (damn Waterloo) one of us mindlessly searches for the name "Memory Swipe" in the app store. And there pops up our app with our logo, icon, pictures and name. Everything was exactly as we had designed it.

There was one slight problem though - none of us had uploaded it to the App store. Apple has a pretty involved app submission process and its not something you can accidently fat-finger from your IDE. Initially we all think that one of us from the team went ahead and started the process but in about 15 mins it became pretty clear that someone had stolen our code.

During this time, being first-time iOS developers, we thought it 'wise' to push to a public repo on GitHub. Who would steal our crappy code, we thought. We didn't wanna pay for a private repo. That was our only mistake.

We check the dates, and the game has been on the app store for about a month now. It also has one update - `V1.1 Some bug fix`. That update was the icing on the cake; whoever was stealing our code was also keeping it up to date will all our recent updates to the repo. They had the audacity to include the message `Some bug fix` without having an inlking on what was fixed. As a matter of fact, if I remember correctly, we had added a feature in that delta.

After fuming for a few hours, we decide to investigate who this was. 

We check our GitHub repo to see who else has forked our code. We realize that several people have forked our code but none of them seemed like our thief. Some of them didn't have Apple developer accounts in the same name, and the ones that did, didn't have our app posted. 

After some further investigation, and some digging through the web, we chance upon the the culprit. A developer account linked to somebody half-way around the world.

Our `thief` has hundreds of well-designed iOS apps to their name. Their apps look completely legit with reviews and comments. They had a phone number, address and different ways to contact them. To anyone else, this was a perfectly

We send emails to that person to take down the app, and even have the courage to call them. (Google Call)

We received emails back in a foreign language which we literally put into google translate to figure out what was being said. Initially they were denying everything and wanted us to show proof. We were pretty distraught at this point since it's really hard to prove

We thought we could scare them by saying we'd sue them and what-not. Tell Apple etc. etc. tell-tale

When looking at the code again we realized one simple fact - `Xcode` puts a default copyright header at the top of every file with the name of the developer and the year. We immediately send back an email detailing that EVERY SINGLE FILE has a copyright header with one of our four names. This really scares them, and we don't hear back for a few weeks.

We get in touch with Apple, and after 

In the meantime, we hastily submit our app for review and it gets rejected for having the word 'Memory'. Apparently that word is copyright in many countries as it clashes with a board game. We remove the space (MemorySwipe) and put it up for review again. This time it fails because matches someone elses code - our thiefs. We complain to apple, mention the Copyright headers, and after a month they take down our thiefs app.

 But by this time several other ones have also sprung up on the app store; some with a slightly different name but same icon, some with a different icon. Our app also gets accepted and is thrown into the mix.
 
 We didn't have the energy to now go after everybody else as well, and so we were pretty 

Lessons learned: 
1. Never push private code to a public repo, no matter how insignificant - if you accidently push a password or key to public repo, you assume its been compromised. 
2. You never know when those annoying copyright headers may come in handy
3. Don't cheap out over security or anonymity















[bearstacks-apps]: https://itunes.apple.com/us/developer/bearstacks-development/id1108705924