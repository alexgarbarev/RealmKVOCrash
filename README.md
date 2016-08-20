# RealmKVOCrash
Example where Realm object with KVO crashes 


# Steps to reproduce 

Just build&run and you'll face that crash sooner or later.

I found that crash happens when you delete Realm object from background thread, while it's observed with KVO on main thread.
Crash isn't happens if you comment KVO observation inside `PersonCell` or comment object deletion inside `ViewController.m`, `runRandomChange` method

![Screenshot](https://dl.dropboxusercontent.com/u/3942667/2016-08-18_17-45-44.png)
