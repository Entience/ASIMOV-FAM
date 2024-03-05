extensions [qlearningextension]

globals [wall-size q-learning_trial_count]
breed [sources source]
breed [bugs bug]
bugs-own [xcor-init ycor-init heading-init sns_left sns_right reward-list vsum vsum-dir vsum-dist slitherometer forward-movement]
patches-own [odor source-color reward endstate?]

to setup
  set wall-size round max-pxcor / 10
  clear-all
  create-sources 1 [
    set shape "circle"
    set size 2
    set color yellow
    setxy (max-pxcor - 2) (2 - max-pycor)
  ]
  create-sources 1 [
    set shape "circle"
    set size 2
    set color 95
    setxy 0 2
    ;setxy (max-pxcor - 2) (max-pycor - 2)
    ;setxy (max-pxcor - 4) (max-pycor - 3)
  ]
  set-current-plot "Ave Reward Per Episode"
  set-plot-y-range -10 10
  set-patch-rewards
  create-bugs 1 [
    set xcor-init 2 - max-pxcor
    set ycor-init max-pycor - 1
    set heading-init 90
    setxy xcor-init ycor-init
   set heading heading-init
    set color 22
    pen-down
  ]
  ask bugs[
    set vsum [0 0]
    qlearningextension:state-def-extra ["vsum-dir" "vsum-dist" "sns_left" "sns_right"] [bla] ;"sns_left" "sns_right" "vsum-dir" "vsum-dist"
    (qlearningextension:actions [goLeft] [goRight])  ;[goLeft] [goRight] [goLeftB] [goRightB]
    qlearningextension:reward [rewardFunc]
    qlearningextension:end-episode [isEndState] resetEpisode
    qlearningextension:action-selection "e-greedy" [0.5 0.08]
    qlearningextension:learning-rate 1
    qlearningextension:discount-factor 0.75

    ; used to create the plot
    create-temporary-plot-pen (word who)
    set-plot-pen-color color
    set reward-list []
  ]

;  repeat 10 [
;    diffuse odor 1
;    ask patches [set pcolor scale-color yellow odor 0 1]
;  ]
end

to go
  ask sources [set odor 1 set source-color color]
  diffuse odor 1
  recolor-patches
  ask bugs [
    update-sensors
    update-state-inputs
    if Enable-Path-Integration [calculate-path-integration]
    qlearningextension:learning
    ;print(qlearningextension:get-qtable)
  ]
end

to recolor-patches
  ask patches [
    ifelse show-Q-rewards [
      set pcolor scale-color red reward -50 20
    ][
      set odor 0.9 * odor set pcolor scale-color white odor 0 1
      if (abs pxcor >= max-pxcor - wall-size) or (abs pycor >= max-pycor - wall-size) [set pcolor 125]
    ]
  ]
end

to update-state-inputs
;  set discretized-sns-odors []
;  let indices range(length sns_odors_left)
;  (foreach indices sns_odors_left sns_odors_right [[n sol sor] ->
;    set discretized-sns-odors (sentence discretized-sns-odors (discretize-senses sol sor))
;    ])
;  set slitherometer_Q precision slitherometer 0
;  set heading_Q precision heading 0
  set vsum-dir precision (item 0 vsum) 0
  set vsum-dist precision (item 1 vsum) 0
;  set-variables q-learning-sns-list discretized-sns-odors
end

to update-sensors
  if abs xcor < max-pxcor and abs ycor < max-pycor [
    let odor_left [odor] of patch-left-and-ahead 40 (0.4 * size)
    ifelse odor_left > 1e-7 [set sns_left 1] [set sns_left 0]

    let odor_right [odor] of patch-right-and-ahead 40 (0.4 * size)
    ifelse odor_right > 1e-7 [set sns_right 1] [set sns_right 0]

    if odor_left > odor_right and sns_right > 0 [set sns_left sns_left + 1]
    if odor_right > odor_left and sns_left > 0 [set sns_right sns_right + 1]
  ]
end

to goRight
  set heading heading + 45
  fd 1
end

to goLeft
  set heading heading - 45
  fd 1
end

to goRightB
  set heading heading + 90
  fd 1
end

to goLeftB
  set heading heading - 90
  fd 1
end


;to goUp
;    set heading 0
;    fd 1
;end
;
;to goDown
;    set heading 180
;    fd 1
;end
;
;to goLeft
;    set heading 270
;    fd 1
;end
;
;to goRight
;    set heading 90
;    fd 1
;end


to resetPosition
  pen-up
  set slitherometer 0 set vsum [0 0]
  set heading heading-init
  setxy xcor-init ycor-init
  pen-down
end

to resetEpisode
  set q-learning_trial_count q-learning_trial_count + 1
  resetPosition
  set-current-plot "Ave Reward Per Episode"
  set-current-plot-pen (word who)
  plot mean reward-list
  set reward-list []
end

to-report bla
  report "c"
end

to set-patch-rewards
  let yellow-source one-of sources with [color = yellow]
  let blue-source one-of sources with [color = 95]
  ask patches [set pcolor black set reward -20]
  ask yellow-source [ask patches in-radius 10 [set reward -1 * (int distance  myself)]]
  ask blue-source [ask patches in-radius 4 [set reward -2 * (int distance  myself)]]
  ask yellow-source [ask patches in-radius 2 [set reward 40 set endstate? true]]
  ask patches [if (abs pxcor > max-pxcor - 2) or (abs pycor > max-pycor - 2) [set reward -100 set endstate? true]]


end

to-report rewardFunc
  set reward-list lput [reward] of patch-here reward-list
  report [reward] of patch-here
end

to-report isEndState
  if [endstate?] of patch-here = true[
    report true
  ]
  report false
end


to calculate-path-integration
  set slitherometer slitherometer + 1
  if slitherometer > 0 [
    set vsum sum-vectors ( list vsum (list heading 1))
  ]
end

to-report round-list [v p] ;Recursive function! to round all elements in a list (even nested)
  ifelse is-list? v [report (map [[vitem] -> (round-list vitem p)] v)] [report precision v p]
end

to-report sum-vectors [vector-list]; vector list in the form of [[a0 l0] [a1 l1] [a2 l2] ...] where "a" is angle, "l" is length of vector
  ifelse is-list? vector-list [
    let angles (map [[vector] -> (item 0 vector)] vector-list)
    let lengths (map [[vector] -> (item 1 vector)] vector-list)
    let x-components (map [[vector] -> ((item 1 vector) * sin (item 0 vector))] vector-list)
    let y-components (map [[vector] -> ((item 1 vector) * cos (item 0 vector))] vector-list)
    let sum-x sum x-components
    let sum-y sum y-components
    let sum-length sqrt ((sum-x ^ 2) + (sum-y ^ 2))
    let sum-angle 0
    if sum-x != 0 and sum-y != 0 [set sum-angle atan sum-x sum-y]
    report (list sum-angle sum-length)
  ][
    report [0 0]
  ]
end


to clear-trails-save-view
  export-view (word "QRUN_trial" q-learning_trial_count "_tick" ticks ".png")
  clear-drawing
end
@#$#@#$#@
GRAPHICS-WINDOW
224
10
508
295
-1
-1
21.231
1
10
1
1
1
0
0
0
1
-6
6
-6
6
0
0
1
ticks
30.0

BUTTON
17
24
81
57
NIL
Setup
NIL
1
T
OBSERVER
NIL
.
NIL
NIL
1

BUTTON
85
24
148
57
Step
Go
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
151
24
214
57
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
14
143
214
293
Ave Reward Per Episode
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

MONITOR
523
34
580
79
sns_left
[sns_left] of one-of bugs
3
1
11

MONITOR
583
34
647
79
sns_right
[sns_right] of one-of bugs
3
1
11

MONITOR
527
121
614
166
vsum
[round-list vsum 0] of one-of bugs
17
1
11

SWITCH
52
105
213
138
show-Q-rewards
show-Q-rewards
1
1
-1000

SWITCH
51
69
213
102
Enable-Path-Integration
Enable-Path-Integration
1
1
-1000

TEXTBOX
523
17
673
35
Sensors:
10
0.0
1

TEXTBOX
526
90
711
116
Path Integration: \n[direction distance]
10
0.0
1

BUTTON
47
300
214
333
Color new paths in yellow
ask bugs [set color yellow]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This is a simple example of ϵ-greedy Q-learning in a very small environment, which is a significantly reduced version of the landmarks environment used in ASIMOV-FAM simulations. The 6x6 patch environment is enclosed by walls, and contains two landmarks that provide odor information. The yellow landmark provides the highest reward in the environment, and serves as an end-state, the blue landmark provides second-highest reward without an end-state, and the walls provide the most negative reward and also serve as an end-state.

The agent's state-space is defined by discretized sensory information it receives from the environment: left odor sensation, right odor sensation, and path-integrated distance and heading information, all of which are displayed on the right-hand side. Path integration can be turned on and off via the "Enable-Path-Integration" switch on the left-hand side.

The agent's action-space is defined simply by two actions: Go Left and Go Right, which turns the agent by 45 degrees, left and right respectively, and moves the agent forward by 1 patch. 

The current Q-learning simulations parameters are: initial ϵ = 0.5, ϵ decay = 0.08, learning rate = 0.99, and discount factor = 0.75.

The **Setup** button sets up the environment and initializes the ϵ-greedy Q-learning algorithm, while the **Step** button runs 1 simulation step of the the Q-learning trials, and **Go** button runs the simulation continuously. After Setup, the reward values of the environment can be visualized via the "show-Q-rewards".

On the left-hand side, the average reward value per trial is displayed over time, and the "Color new paths in yellow" function can be used to color all new agent trajectories in yellow, which helps in identifying if trajectories have converged.

## THINGS TO NOTICE

In this small environment, after a short time of training with Q-learning (< 700 trials), the agent's trajectories may converge to the shortest paths between its start position and the landmarks (with yellow landmark as an end-point), which maximizes reward. Without path integration information, the Q-learning trials are much less successful.
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
NetLogo 6.4.0
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
0
@#$#@#$#@
