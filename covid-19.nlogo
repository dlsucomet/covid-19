; Global constants
globals [
  ; Denotes the range of a person's heading
  heading-range

  ; Denotes the range of a person's forward movement
  forward-movement-range

  ; Denotes the range of a person's vision
  vision

  ; Denotes the the maximum angle of a person's vision
  angle

  ; Denotes the horizontal limit of the inside area
  horizontal-inside-bound

  ; Denotes the vertical limit of the inside area
  vertical-inside-bound

  ; Denotes a slight margin of error in order to avoid people spawning exactly on the edge of their area
  margin-of-error

  ; Denotes the previous state of non-movement
  is-non-movement-before

  ; Denotes the list of the only agents allowed to move
  allowed-list

  ; Denotes the death rate for the COVID-19
  ; (https://www.who.int/docs/default-source/coronaviruse/situation-reports/20200306-sitrep-46-covid-19.pdf?sfvrsn=96b04adf_2)
  death-rate

  ; Denotes the mean incubation period for the virus (in hours)
  ; (https://www.jwatch.org/na51083/2020/03/13/covid-19-incubation-period-update)
  mean-incubation-period

  ; Denotes the mean duration of the virus (in hours) from when symptoms start appearing (after the incubation period) to potential recovery
  ; (https://ourworldindata.org/coronavirus#how-long-does-covid-19-last)
  mean-duration
]

; Patch variables
patches-own [
  ; Denotes whether this patch is part of the inside area or not
  is-inside
]

; Turtle variables
turtles-own [
  ; Denotes whether this person is infected with the COVID-19 virus or not
  is-infected

  ; Denotes whether this person is immune or not
  ; A person who survives the virus will be immune to it
  ; (https://www.independent.co.uk/life-style/health-and-families/coronavirus-immunity-reinfection-get-covid-19-twice-sick-spread-relapse-a9400691.html)
  is-immune

  ; Denotes how long it will take until this person starts showing symptoms
  incubation-period-left

  ; Denotes how long it will take until this person gets better from the time of infection (if the person doesn't die)
  time-infected-left
]

; Set the breeds up
breed [insiders insider]
breed [outsiders outsider]

; Set the model up
to setup
  ; Start form a clean slate
  clear-all
  reset-ticks

  ; Set the global variables
  set-globals

  ; Set the environment up
  set-patches

  ; Set the agents up
  set-people
end

; Set all global constants
to set-globals
  set heading-range 45
  set forward-movement-range 2

  set vision 2
  set angle 180

  set horizontal-inside-bound 15
  set vertical-inside-bound 15
  set margin-of-error 1

  set allowed-list turtles

  ifelse non-movement [
    set is-non-movement-before 0
  ][
    set is-non-movement-before 1
  ]

  set death-rate 0.03
  set mean-incubation-period 132
  set mean-duration 336
end

; Set all patches
to set-patches
  ; Label an inside square as the inside area, then color it appropriately
  ; Color the resulting outside areas appropriately as well
  ask patches [
    ; If the patch is within the bounds specified as part of the inside area, label and color it as such
    ifelse pxcor >= (- horizontal-inside-bound) and pxcor <= horizontal-inside-bound and pycor >= (- vertical-inside-bound) and pycor <= vertical-inside-bound [
      set is-inside 1
      set pcolor 7
    ] [
      set is-inside 0
      set pcolor 9
    ]
  ]
end

; Set all people
to set-people
  ; Use a person graphic
  set-default-shape turtles "person"

  ; This person hasn't been infected yet (for now)
  ask turtles [
    set is-infected 0
    set is-immune 0
    set incubation-period-left 0
    set time-infected-left 0
  ]

  set-insiders
  set-outsiders
end

; Set the insiders up
to set-insiders
  ; First of all, set the number of insiders initially inside (their area)
  create-insiders insiders-inside-count [
    setxy ((random-float (2 * (horizontal-inside-bound - margin-of-error) + 1)) - (horizontal-inside-bound - margin-of-error)) ((random-float (2 * (vertical-inside-bound - margin-of-error) + 1)) - (vertical-inside-bound - margin-of-error))

    ; Determine if this person will initially have the virus (depending on the user input)
    ifelse random-float 100 < insiders-inside-infected [
      get-infected
    ] [
      set color 35
    ]
  ]

  ; Then set the number of insiders initially outside (not their area)
  create-insiders insiders-outside-count [
    let candidate-x random-xcor
    let candidate-y random-ycor

    while [candidate-x + margin-of-error >= (- horizontal-inside-bound) and candidate-x - margin-of-error <= horizontal-inside-bound and candidate-y + margin-of-error >= (- vertical-inside-bound) and candidate-y - margin-of-error <= vertical-inside-bound][
      set candidate-x random-xcor
      set candidate-y random-ycor
    ]

    setxy candidate-x candidate-y

    ; Determine if this person will initially have the virus (depending on the user input)
    ifelse random-float 100 < insiders-outside-infected [
      get-infected
    ] [
      set color 35
    ]
  ]
end

; Set the outsiders up
to set-outsiders
  ; First of all, set the number of outsiders initially outside (their area)
  create-outsiders outsiders-outside-count [
    let candidate-x random-xcor
    let candidate-y random-ycor

    while [candidate-x + margin-of-error >= (- horizontal-inside-bound) and candidate-x - margin-of-error <= horizontal-inside-bound and candidate-y + margin-of-error >= (- vertical-inside-bound) and candidate-y - margin-of-error <= vertical-inside-bound][
      set candidate-x random-xcor
      set candidate-y random-ycor
    ]

    setxy candidate-x candidate-y

    ; Determine if this person will initially have the virus (depending on the user input)
    ifelse random-float 100 < outsiders-outside-infected [
      get-infected
    ] [
      set color 36
    ]
  ]

  ; Then set the number of outsiders initially inside (not their area)
  create-outsiders outsiders-inside-count [
    setxy ((random-float (2 * (horizontal-inside-bound - margin-of-error) + 1)) - (horizontal-inside-bound - margin-of-error)) ((random-float (2 * (vertical-inside-bound - margin-of-error) + 1)) - (vertical-inside-bound - margin-of-error))

    ; Determine if this person will initially have the virus (depending on the user input)
    ifelse random-float 100 < outsiders-inside-infected [
      get-infected
    ] [
      set color 36
    ]
  ]
end

; Infect this person
to get-infected
  set is-infected 1

  ; Set the incubation period and duration (in hours) based on the given averages
  set incubation-period-left floor (random-normal mean-incubation-period 1)

  ; Take the incubation period into consideration when setting up the countdown for the duration of the disease
  set time-infected-left floor ((random-normal mean-duration 1) + incubation-period-left)

  set color 63
end

; Run the model
to go
  ; If there are no more infections, halt
  if count turtles with [is-infected = 1] = 0 [
    stop
  ]

  ; If non-movement measures are proposed, prepare the list of only agents to be allowed
  ifelse non-movement [
    if is-non-movement-before = 0 [
      set is-non-movement-before 1

      let turtle-count count turtles
      set allowed-list n-of ((100 - non-movement-percentage) / 100 * turtle-count) turtles
    ]
  ][
    if is-non-movement-before = 1 [
      set is-non-movement-before 0
    ]
  ]

  ask turtles [
    ; Make the people move around
    ; If non-movement measures are in place, check if they are allowed
    if (not non-movement) or (non-movement and member? self allowed-list) [
      move-people
    ]

    ; Manage each person's infection status
    manage-infection
  ]

  tick
end

; Manage each person's infection status
to manage-infection
  ; Manage infected people
  if is-infected = 1 [
    ; If the patch this person is on has other people on it and at least one of those people are infected, there is a chance that this person will infect the others too
    ask other turtles-here with [
      is-infected = 0 and is-immune = 0
    ][
      if random-float 100 < infectiousness [
        get-infected
      ]
    ]

    ; Should this person die?
    ; The average death rate is 3% - we assume that this is the case over the average duration of the virus (336 hours or 2 weeks)
    ; Hence, there should be a 3% / 336 (~0.009%) chance of dying each hour
    if random-float 1 < (death-rate / mean-duration) [
      die
    ]

    ; Count down the virus incubation and duration period
    if incubation-period-left > 0 [
      set incubation-period-left incubation-period-left - 1
    ]

    ifelse time-infected-left > 0 [
      set time-infected-left time-infected-left - 1
    ][
      ; If the time infected has lapsed, the person is now healthy again (and immune to the virus)
      set is-infected 0
      set is-immune 1

      ifelse breed = insiders [
        set color 35
      ][
        set color 36
      ]
    ]
  ]

end

; Move each person
to move-people
  ; Try moving some heading and distance away
  let candidate-heading (random-float (2 * heading-range + 1) - heading-range)
  let candidate-movement ((random-float forward-movement-range) / 5)

  right candidate-heading
  let candidate-patch patch-ahead candidate-movement

  ; If there are avoidance measures enforced...
  if avoidance [
    if random-float 100 < avoidance-percentage [
      ; Decide whether to enforce it on this specific person (depends on the percentage of the avoidance)
      if any? (other turtles in-cone vision angle) [
        set candidate-movement 0
      ]
    ]
  ]

  ; If there is a lockdown enforced...
  if is-lockdown [
    ; Decide whether to enforce it on this specific person (depends on the strictness of the lockdown)
    if random-float 100 < lockdown-strictness [
      ; If the person is going from outside to inside, or from inside to outside, don't allow it to; make the person go another direction
      while [(([is-inside] of patch-here = 0 and [is-inside] of candidate-patch = 1) or ([is-inside] of patch-here = 1 and [is-inside] of candidate-patch = 0))] [
        set candidate-heading (random-float (2 * heading-range + 1) - heading-range)

        right candidate-heading
        set candidate-patch patch-ahead candidate-movement
      ]
    ]
  ]

  forward candidate-movement
end
@#$#@#$#@
GRAPHICS-WINDOW
434
10
930
507
-1
-1
8.0
1
10
1
1
1
0
1
1
1
-30
30
-30
30
1
1
1
hours
30.0

BUTTON
50
10
223
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
235
10
430
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
50
75
222
108
insiders-inside-count
insiders-inside-count
0
500
100.0
1
1
NIL
HORIZONTAL

SLIDER
50
197
223
230
outsiders-outside-count
outsiders-outside-count
0
500
100.0
1
1
NIL
HORIZONTAL

SLIDER
50
117
222
150
insiders-outside-count
insiders-outside-count
0
500
100.0
1
1
NIL
HORIZONTAL

SLIDER
50
157
222
190
outsiders-inside-count
outsiders-inside-count
0
500
100.0
1
1
NIL
HORIZONTAL

SWITCH
50
315
225
348
is-lockdown
is-lockdown
1
1
-1000

SLIDER
234
315
429
348
lockdown-strictness
lockdown-strictness
1
100
90.0
1
1
%
HORIZONTAL

SLIDER
235
77
430
110
insiders-inside-infected
insiders-inside-infected
0
100
1.0
1
1
%
HORIZONTAL

SLIDER
235
117
430
150
insiders-outside-infected
insiders-outside-infected
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
235
157
430
190
outsiders-inside-infected
outsiders-inside-infected
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
235
197
430
230
outsiders-outside-infected
outsiders-outside-infected
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
50
255
430
288
infectiousness
infectiousness
1
100
10.0
1
1
%
HORIZONTAL

PLOT
935
10
1335
255
Total COVID-19 infections
time
number of people
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"total infected" 1.0 0 -2674135 true "" "plot count turtles with [is-infected = 1]"
"population" 1.0 0 -7500403 true "" "plot count turtles"
"insiders infected" 1.0 0 -13840069 true "" "plot count insiders with [is-infected = 1]"
"outsiders infected" 1.0 0 -13345367 true "" "plot count outsiders with [is-infected = 1]"

MONITOR
935
260
1025
305
Infected people
count turtles with [is-infected = 1]
17
1
11

MONITOR
1030
260
1115
305
Healthy people
count turtles with [is-infected = 0]
17
1
11

MONITOR
1120
260
1335
305
Population
count turtles
17
1
11

PLOT
935
310
1130
460
Insider infections
time
number of people
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"infected" 1.0 0 -13840069 true "" "plot count insiders with [is-infected = 1]"
"population" 1.0 0 -7500403 true "" "plot count insiders"

PLOT
1135
310
1335
460
Outsider infections
time
number of people
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot count outsiders with [is-infected = 1]"
"population" 1.0 0 -7500403 true "" "plot count outsiders"

MONITOR
935
465
1035
510
Infected insiders
count insiders with [is-infected = 1]
17
1
11

MONITOR
1040
465
1130
510
Healthy insiders
count insiders with [is-infected = 0]
17
1
11

MONITOR
1135
465
1235
510
Infected outsiders
count outsiders with [is-infected = 1]
17
1
11

MONITOR
1240
465
1335
510
Healthy outsiders
count outsiders with [is-infected = 0]
17
1
11

SWITCH
50
470
225
503
avoidance
avoidance
1
1
-1000

SWITCH
50
430
225
463
non-movement
non-movement
1
1
-1000

SLIDER
235
430
430
463
non-movement-percentage
non-movement-percentage
1
100
90.0
1
1
%
HORIZONTAL

TEXTBOX
50
60
200
78
Initial population controls
11
0.0
1

TEXTBOX
50
240
200
258
Virus infectiousness control
11
0.0
1

TEXTBOX
50
380
420
425
Social distancing measures\nNOTE: Changes to the non-movement percentage slider may only be made when the movement percentage slider is off.
11
0.0
1

TEXTBOX
50
300
200
318
Lockdown controls
11
0.0
1

SLIDER
235
470
430
503
avoidance-percentage
avoidance-percentage
1
100
90.0
1
1
%
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

On November or December 2019, a virus called the Severe acute respiratory syndrome coronavirus 2 (SARS-CoV-2) was first transmitted to humans, from what is thought to be an animal origin, causing a highly contagious disease. Many months later, it has become the cause of a full-blown pandemic with devastating worldwide ramifications. This disease was given the name **Coronavirus disease 2019 (COVID-19)**.

Numerous prevention measures have been devised by different authorities all around the world in an effort to "flatten the curve", referring to the attempt to decrease the peak of the disease's epidemic curve, or at to least prolong the incidence of infections over a larger period of time to avoid overwhelming health services. Some of these measures include:

- A forced quarantine, or a **lockdown**, referring to the practice of isolating a region to prevent infections from spilling over outside of it or spreading into it.

- **Social distancing** measures, referring to the practice of avoiding social contact in an effort to prevent oneself from being *infected* and/or to prevent oneself from being the *infector*.

Numerous studies and simulations have been conducted by researchers on the attempted dampening of the spread of the virus through the measures above. *This agent-based model attempts do the same, but introduces the concept of regions and how the virus spreads between them, as well as how the preventive measures affect the transmission of the virus not just between the people, but between different regions as well.*

## HOW IT WORKS
### Regions and people

There are two regions defined in this model, an inner region (**inside**) and an outer one (**outside**). There are people who live in these regions. People who live inside are called **insiders** while the ones who live outside our called **outsiders**. However, these people do not necessarily reside in their home regions at any given time. Outsiders may visit inside, and insiders may visit outside. Just like real-world regions, people who live in a place do not necessarily have to be *there* in that place. This model takes that observation into account.

### The virus and its effects
When a person gets COVID-19, that person likely won't immediately experience any symptoms. It may take some time for it to show (or maybe none at all, in the case of asymptomatic people, but that's out of this model's scope). This period is called the **incubation period** of the virus - the period between when a person first gets infected with the virus and when a person actually shows symptoms due to the virus. The mean incubation period of the virus is 5.5 days (132 hours) [1]. This has been considered in the model (go look at the code - it's there).

After a person starts displaying symptoms, the mean time until a person recovers from it is around two weeks (336 hours) [2]. This period is referred to as the **duration** of the virus - the period between when a person first shows symptoms of the virus and when a person recovers from it. That is, if the person *does* recover. The thing is, the virus carries a mortality rate of around 3% [3]. In reality, the morality rate differs with the age range of an infected patient. However, this model does not incorporate the concept of age. All persons are *ageless*, and no people die of old age in the model. What people *may* die of is the coronavirus, of course. However, when they don't, they recover. And when they do recover, that person is assumed to be permanently immune from the virus [4].

### Preventive measures
Three types of preventive measures are featured in this model. First is the **lockdown**, as explained earlier. When the lockdown is in place, people may not travel between the regions. The other measures fall under social distancing, and this model identifies two of them, **non-movement** and **avoidance**. Non-movement is the practice of simply staying put to maintain social distance with others, while avoidance is the practice of actively maintaining spaces between other people.

### Model overview
The model starts with a set number of people with the virus. The people move about randomly anywhere (except when preventive measures are in place, of course). The time in the model is measured in terms of **hours**, and it is every hour when the people try to move. When people occupy the same space in the model, there is a chance that the other people in that space gets infected. Otherwise, the virus stays with the person until that person either dies from it or recovers from it. The model stops when there are no more COVID-19 infections in all of the people.


## HOW TO USE IT

### Setup and go
The setup button is used to set the model's initial state up, while the go button is used to start running the model (or to pause it). Before clicking the setup button, make sure that you have set the initial population controls to what you desire. You may also choose the appropriate percentages of the population who initially have infections. Note that because the model stops immediately when there are no more infected people, you may have to press setup a few more times until a few infected people are initially created.

### Virus infectiousness control
As stated earlier, when an infected person occupies a space in the model with other people in it, there is a chance that at least one of those people will become infected. That chance is dictated by the virus infectiousness control slider wherein one may select an infection rate of 1% (very unlikely to infect someone) to 100% (all people who come in contact with an infected person become infected as well). Take note that in reality, the infection rate of the virus is denoted by far more complicated variables and parameters such as the virus' basic reproduction number, which says how many other infections a person is responsible for on average. But that is out of this model's scope for now.

### Lockdown controls
This dictates whether people may travel in between the regions or not. You may also choose how strict the lockdown is going to be, from 1% (very lax) to 100% (absolute lockdown).

### Social distancing measures
There are two classes of controls under the social distancing measures. First are the non-movement controls. The controls contain a switch to turn non-movement on or off. The percentage of people practicing non-movement are controlled by the non-movement percentage slider next to the switch, from 1% (very few people practicing it) to 100% (everyone does not move). Note that the non-movement percentage slider only takes effect on the model every time the non-movement switch has been turned on from the off position. Internally, what this does is create a list of "whitelisted" people that are allowed to move, of course reflecting the appropriate percentage as selected by the slider.

The second control, the avoidance switch, merely activates or deactivates the practice of separation between all people. When the avoidance switch is on, each person has a "visibility cone" 180 degrees wide and 2 units ahead. Whenever a person sees someone else in here, the person does not continue to make his/her planned move to avoid that person. The number of people who practice avoidance is controlled by the avoidance percentage slider.


## THINGS TO NOTICE
Set the initial population up. Remember the total number of people you have set up. Run the model and let the COVID-19 infections swell and then decline. Several plots and monitors are shown to the right. Note that the plots show a gray line which starts high and then may slightly decline. Also note a monitor called *population*. This describes the total population of all people in the model. You may notice that this number is slightly less than your initial population setup. This is because some people have actually died due to the infection. Though you may sometimes not observe deaths when your initial populations are small enough (meaning everyone survived the outbreak).


## THINGS TO TRY
How would you "flatten the curve"? The goal of the preventive measures is to flatten the epidemic curve. That is, the goal is to prevent a large acceleration in the number of cases.

Play around with the sliders and experiment with different combinations of preventive measures as well as with the differing population densities between of the regions. See how well each combination of measures and parameters flattens the epidemic curve. Here are some things you could explore:

- Which appears to be the most effective combination of measures to flatten the curve?
- Is there a single measure which appears to be the most effective way to flatten the curve?
- What happens when a measure is implemented when the virus has already infected a lot of people? Would it still be effective?
- What happens when a measure is lifted when a number of people have already recovered? Would it be safe to do so? Or would this trigger another surge of infection rates?
- What happens when the strictness of a measure is modified while it is in place? How would this affect the infection rate of the virus?


## EXTENDING THE MODEL
More parameters could be added to this model. Perhaps the basic reproduction number could be modeled in an agent-based context. Or maybe incorporate some crowd clumping characteristics which humans are known to do and see how that impacts the spread of the infections.


## RELATED MODELS
This model is inspired by the Virus model under the Biology section. I've omitted some of its features (e.g., the concept of aging and creating offspring) and pegged some values to a fixed constant (e.g., mortality rate) in order to focus on the aspects of the specific virus causing the COVID-19 pandemic.

## CREDITS AND REFERENCES

[1] https://www.jwatch.org/na51083/2020/03/13/covid-19-incubation-period-update
[2] https://ourworldindata.org/coronavirus#how-long-does-covid-19-last
[3] https://www.who.int/docs/default-source/coronaviruse/situation-reports/20200306-sitrep-46-covid-19.pdf?sfvrsn=96b04adf_2
[4] https://www.independent.co.uk/life-style/health-and-families/coronavirus-immunity-reinfection-get-covid-19-twice-sick-spread-relapse-a9400691.html
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
