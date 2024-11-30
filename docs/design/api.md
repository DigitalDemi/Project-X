# Different API's used


In this project I plan to use different apis to interact with my app

- Calender -> ics 
- Todo -> todoist 
- prioritisation matrix -> prioritisation -> skills
- Habit tracking (This is done though many way, apps, obsidian, notion)
- Note taking application (Obisidian)

# Develop REST API


The backend can be done with couple of languages I have decieding between doing it with scale, node js or python (flask)

This is because with scala due to the nature of the language I know it is scalable. 

Node js because I am used to the java echo system

python due flkask and allowing data visualisation to be done with pandas and matplot lib. 

However the algorithms I may develop, if done  in a functional manner I know that the correctness is guarrented.

Intinally while develloping I will just be using sqlite as I dont need a database service intinally and just focus and being able to redproduce everyhting locally. 

I need to learn about more about neoks I have never used grpah database before the main reason I have considered this is due to the graph nature of connecting each notes and how you consider relationships and not trying force a way of thinking while developing my application.

# References

- https://developer.todoist.com/guides/#developing-with-todoist
- https://developers.google.com/calendar/api/guides/overview
- https://docs.obsidian.md/Home
- https://github.com/coddingtonbear/obsidian-local-rest-api

# Anki
Anki web was designed so that you use the computer version of anki to sync with other deivces, therefore a simliur approch will be taken with
the app.

- https://github.com/ankitects/anki/tree/main/docs/syncserver
- https://ankiweb.net/about


# Calender System
The calender system, I was intionally going to use the google calender api to change the persons schdule however I think it makes more sense to have no dependency and use an ics server that will generate an ics file and then the person can subcribe to it.

- https://en.wikipedia.org/wiki/ICalendar

