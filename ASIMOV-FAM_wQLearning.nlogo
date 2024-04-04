;;=====================================================================================================================================================================================
;;=====================================================================================================================================================================================
;;;
;;;                                          A        S        I         M         O         V
;;;
;;=====================================================================================================================================================================================
;;=====================================================================================================================================================================================



;;==========================================================================================================================================
;;                                                   V A R I A B L E    I N I T I A L I Z A T I O N
;;==========================================================================================================================================

extensions [matrix csv qlearningextension]

;;Create animats and assign qualities
globals [data Addiction_Cycle_Phase switch_time stop_time prey-types-list prey-color-list odor-color-list odor-types-list variables-list variable-labels num-odor-types prey-odor-matrix diffc evapc
         cluster-x-coordinates cluster-y-coordinates plot-timer wallcount dcount Presenting Present-y-coord pstep pticks Static-Environment Spatial-Mapping-Enabled var-val-list
         exp-mode-list exp-mode-agent-pos-matrix q-learning_trial_count]

breed [arms arm]
breed [Cslugs Cslug]
breed [nociceptors nociceptor] ;ie the pain receptors
breed [prey prey-item] ;includes hermi, flab, fauxflab, drug
breed [pebbles pebble]
breed [color-effects color-effect]
breed [memory-pointers memory-pointer]
breed [wallpts wallpt]
;breed [flabs flab]
;breed [hermis hermi]
;breed [fauxflabs fauxflab]
;breed [drugs drug]

turtles-own [non-edible fixed]
prey-own [prey-type]

Cslugs-own [ Somatic_Map App_State App_State_Switch ExpReward_pos ExpReward_neg iSum Incentive Nutrition Satiation speed forward-movement turn-angle
             sns_betaine sns_betaine_left sns_betaine_right sns-pain-left sns-pain-right sns-pain-caud sns-pain spontaneous-pain pain pain-switch
             odors_left odors_right sns_odors_left sns_odors_right sns_odors Somatic_Map_Factors Somatic_Map_Sigmoids
             num_senses sense_names senses imag_senses imag_senses_accumulators senses_left imag_senses_left senses_right imag_senses_right sense_colors
             hermcount flabcount fauxflabcount drugcount drug_reward
             R R_hermi R_flab R_drug RewardExperience deg_sensitization IN M M0 W1 W2 W3 dW3 W4 W5
             inputs inputs_left inputs_right num_inputs traces memory_traces input_labels input_colors
             i j FAMatrix_dim init_list FAMatrix_diff-A FAMatrix_cross-A FAMatrix_strengths FAMatrix_timelags FAMatrix_rewards FAMatrix_vdir FAMatrix_vdist FAMatrix_vec FAMatrix_vtemp FAMatrix_vseq reward_pos reward_neg
             Incentives Imag_Incentives Realsense_Rewards Direct_Rewards DirectReward_i Imag_Rewards ImagReward_i
             slitherometer head-direction vsum stepsize trace-track vseq_temp vseq_count vseq_sum detour-vector correction-vector HDOut HDWeight HD0 HDtau
             HLB HLS HLD sensor_angle lsns_vec rsns_vec left_dist right_dist dist; half-length-body half-length-sensor half-length-diagonal
             turn-angle-accumulation trace-changes
             strengths_RW strengths_RW_i alpha_RW beta_RW lambda_RW
             q-learning-var-list q-learning-sns-list discretized-sns-odors reward-list_Q slitherometer_Q heading_Q vsum-dir_Q vsum-dist_Q
             slB_Q srB_Q slH_Q srH_Q slF_Q srF_Q slD_Q srD_Q slO5_Q srO5_Q slO6_Q srO6_Q slO7_Q srO7_Q slO8_Q srO8_Q slO9_Q srO9_Q slO10_Q srO10_Q
]
nociceptors-own [parent painval id hit]
arms-own [parent phase id]
patches-own [odor-list odor_betaine odor_hermi odor_flab odor_drug odor5 odor6 odor7 odor8 odor9 odor10 marine-colors wall reward_Q endstate?_Q]
color-effects-own [large-color-effect]
memory-pointers-own [id parent targ dist dir]
links-own [mdist mdir mstr mord mrew text]
wallpts-own [wall-id]


;-----------------------------------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------------------------------

;;==========================================================================================================================================
;;                                                   S E T U P    P R O C E D U R E S
;;==========================================================================================================================================

to Setup
  clear-all
  reset-ticks

  ;Set up globals:
  ;-----------------------
  ; sets up first phase of Addiction Cycle, to be used when Addiction_Cycle is turned ON
  set Pause-At-Tick: 0
  set Screenshot-At-Ticks: "";"0 314 730 770 930 950 990 1100 1200 1250 1300 2000 3000 4000 10000"
  set Force-Turn 0
  set Addiction_Cycle_Phase "Drug-Free"
  set Presenting "" ; for printing out presentation sequence
  set File-Name "FAMdata.csv"
  set Present-y-coord -6
  ;set switch_time 15000
  set switch_time 5000
  set stop_time 1000000; was 60000, 150000
  set prey-types-list ["hermi" "flab" "fauxflab" "drug" "p5" "p6" "p7" "p8" "p9"]
  set prey-color-list [85 135 125 45 35 65 75 105 115]
  set odor-types-list ["odor_betaine" "odor_hermi" "odor_flab" "odor_drug" "odor5" "odor6" "odor7" "odor8" "odor9" "odor10"]
  set odor-color-list [9.9 85 135 45 35 65 75 105 115 125]
  ;set variables-list ["Odor 2" "Odor 1" "Odor 3" "Odor 5" "Odor 6" "Odor 7" "Odor 8" "Odor 9" "Pain" "Reward" "R-"]
  ;sns_odors_left
  ;["Odor 2 Left" "Odor 1 Left" "Odor 3 Left" "Odor 5 Left" "Odor 6 Left" "Odor 7 Left" "Odor 8 Left" "Odor 9" "Pain" "Reward" "R-"]
  set num-odor-types length odor-types-list
  set prey-odor-matrix [ [0.0   0.5   0     0     0    0    0    0    0    0]  ;hermi odor for hermi prey; previously also used betaine odor
                         [0.0   0     0.5   0     0    0    0    0    0    0]  ;flab odor for flab prey; previously also used betaine odor
                         [0.0   0     0.5   0     0    0    0    0    0    0]  ;flab odor for fauxflab prey; previously also used betaine odor
                         [0     0     0     0.5   0    0    0    0    0    0]  ;drug odor for drug items
                         [0     0     0     0     0.5  0    0    0    0    0]  ;odor5 for prey5
                         [0     0     0     0     0    0.5  0    0    0    0]  ;odor6 for prey6
                         [0     0     0     0     0    0    0.5  0    0    0]  ;odor7 for prey7
                         [0     0     0     0     0    0    0    0.5  0    0]  ;odor8 for prey8
                         [0     0     0     0     0    0    0    0    0.5  0]  ;odor9 for prey9
                       ]
  set exp-mode-list ["Temporal Sequence Learning" "Spatial Sequence Learning" "3 Source Spatial Mapping" "5 Source Spatial Mapping" "Obstacle Avoidance Learning" "Prey Populations"]
  set exp-mode-agent-pos-matrix  [ [0 0 -6]               [ 0 0 -70]                   [30 0 0]                      [30 0 0]                [150 7 50]                 [0 0 0]]   ;; heading x-coord y-coord
  setup-ASIMOV-Agent
  setup-Environment
  ask Cslugs [update-arms set turn-angle-accumulation heading pen-down] ;Track Cslug's path
end

;---------------------------------------------------------------------------------
;           Spawns the ASIMOV agent, sets up its variables
;---------------------------------------------------------------------------------
to setup-ASIMOV-Agent
  create-Cslugs 1 [
    ;sets shape, size, color, and position of octo/slug
    ifelse member? "Sequence Learning" experiment_mode or member? "Prey Populations" experiment_mode[ ;slug shape for sequence learning and prey populations, octo for all others
      set shape "cslug2" ; "slug"
      set color 115
      set size 16
      set heading 0
    ][
      set shape "octobody2" ; "octo"
      set color 35
      set size 13
      set heading 30
      ;Give octo moving arms for decorative effect
      repeat 8[
        hatch-arms 1 [
          set size 19
          set color 35
          set heading 0
          set parent myself
          let idnum ((count arms) mod 8)
          let labels ["armo1l" "armo2l" "armo3l" "armo4l" "armo1r" "armo2r" "armo3r" "armo4r"]
          set id (item idnum labels)
          set shape id
        ]
      ]
    ]

    set HLB 3.98
    set HLS 3.34
    set HLD sqrt((HLB ^ 2) + (HLS ^ 2))
    set sensor_angle atan HLS HLB

    ;creates 7 sensors for pain detection
    repeat 7 [
      hatch-nociceptors 1 [
        set hidden? true
        set shape "dot"
        set size 3
        set parent myself
        let idnum ((count nociceptors) mod 7)
        let labels ["snsrOL" "snsrOR" "snsrUL" "snsrUR" "snsrBL" "snsrBR" "snsrBM"]
        set id (item idnum labels)
        if id = "snsrOL" or id = "snsrOR"[set hidden? false]
      ]
    ]
    ;updates pain sensor position
    update-nociceptor-position

    ;sets baseline spontaneous pain activity
    set spontaneous-pain 2

    ;sets initial values for feeding network variables (nutrition, incentive salience, somatic map, and satiation)
    set Nutrition 0.01
    set Incentive 0
    set Somatic_Map 0
    set Satiation 0.01

    ;sets initial habituation/sensitization parameters for Homeostatic Reward Circuit (HRC):
    set W1 1
    set W2 0.2
    set W3 1
    set W4 0.1
    set W5 0.1
    set M0 10 ;Baseline activity for M
    ;set R_drug 0.5
    set drug_reward 10
    set HD0 0.5
    set HDWeight 1
    set HDtau 100

    ;sets up the Feature Association Matrix
    set inputs [0 0 0 0 0 0 0 0 0 0 0] ;first 9 for sensory inputs, last 2 for reward (+,-) inputs
    set inputs_left inputs
    set inputs_right inputs
    set traces [0 0 0 0 0 0 0 0 0 0 0]
    set trace-changes traces

    ;set inputs (list sns_hermi sns_flab sns_drug sns-pain reward_pos reward_neg)
    set num_inputs length inputs

    set FAMatrix_dim length inputs
    set init_list []
    repeat FAMatrix_dim [set init_list lput (n-values FAMatrix_dim [0]) init_list]
    let init_vseq_list []
    let init_vseq_row []
    repeat FAMatrix_dim [set init_vseq_row lput ([0 0]) init_vseq_row]
    repeat FAMatrix_dim [set init_vseq_list lput (init_vseq_row) init_vseq_list]

    set FAMatrix_cross-A matrix:from-row-list init_list
    set FAMatrix_diff-A matrix:from-row-list init_list

    set FAMatrix_strengths matrix:from-row-list init_list
    set FAMatrix_timelags matrix:from-row-list init_list
    set FAMatrix_rewards matrix:from-row-list init_list
    set FAMatrix_vdir matrix:from-row-list init_list
    set FAMatrix_vdist matrix:from-row-list init_list
    set FAMatrix_vseq init_vseq_list
    set FAMatrix_vec init_vseq_list
    set FAMatrix_vtemp init_vseq_list

    set stepsize 0
    set vsum (list heading stepsize)

    set Somatic_Map_Sigmoids n-values ((num-odor-types - 1) + 1) [0]
    set Incentives n-values ((num-odor-types - 1) + 1) [0]
    set Imag_Incentives n-values ((num-odor-types - 1) + 1) [0]
    set Direct_Rewards n-values ((num-odor-types - 1) + 1) [0]
    set Imag_Rewards n-values ((num-odor-types - 1) + 1) [0]
    set Realsense_Rewards n-values ((num-odor-types - 1) + 1) [0]
    set imag_senses n-values ((num-odor-types - 1) + 1) [0]
    set imag_senses_accumulators n-values ((num-odor-types - 1) + 1) [0]
    set imag_senses_left n-values ((num-odor-types - 1) + 1) [0]
    set imag_senses_right n-values ((num-odor-types - 1) + 1) [0]
    set sns_odors_left n-values num-odor-types [0]
    set sns_odors_right n-values num-odor-types [0]
    set sns_odors n-values num-odor-types [0]
    ;set input_labels ["Hl" "Hr" "Fl" "Fr" "Dl" "Dr" "Pl" "Pr" "R+" "R-"]
    set input_labels ["H" "F" "D" "O5" "O6" "O7" "O8" "O9" "P" "R+" "R-"]
    ;set input_labels ["H" "F" "D" "P" "R+" "R-"]
    ;set input_colors [83 85 133 135 43 45 13 15 25 22]
    set input_colors [85 135 45 35 65 75 105 115 15 25 22]
    ;set input_colors [85 135 45 15 25 22]

    ;sets up Rescorla-Wagner Algorithm parameters
    set strengths_RW n-values ((num-odor-types - 1) + 1) [0]
    set alpha_RW 0.8
    set beta_RW 1
    set lambda_RW 1

    ;sets up Q-Learning
    if member? "Q-Learning" LEARNING_MODE [
      set q-learning-var-list parse-string "slitherometer_Q heading_Q vsum-dir_Q vsum-dist_Q slB_Q srB_Q slH_Q srH_Q slF_Q srF_Q slD_Q srD_Q slO5_Q srO5_Q slO6_Q srO6_Q slO7_Q srO7_Q slO8_Q srO8_Q slO9_Q srO9_Q slO10_Q srO10_Q" " " false
      set q-learning-sns-list sublist q-learning-var-list 4 (length q-learning-var-list)
      if QL-minimal-states? [set q-learning-var-list parse-string "vsum-dir_Q vsum-dist_Q" " " false]
      qlearningextension:state-def-extra q-learning-var-list [bla]
      set Direct_Rewards n-values num-odor-types [1] ; make landmarks attractive by default
      if LEARNING_MODE = "Q-Learning (Turn Left/Right)" [(qlearningextension:actions [goLeft] [goRight])]
      if LEARNING_MODE = "Q-Learning (Approach/Avoid)" [(qlearningextension:actions [Approach] [Avoid])]
      qlearningextension:reward [rewardFunc]
      qlearningextension:end-episode [isEndState] resetEpisode
      qlearningextension:action-selection "e-greedy" [0.8 0.99995]
      qlearningextension:learning-rate 0.99
      qlearningextension:discount-factor 0.75
      ; used to create the plot

      set-current-plot "Ave Reward Per Episode"
      set-plot-y-range -10 10
      create-temporary-plot-pen (word who)
      set-plot-pen-color color
      set reward-list_Q []
    ]


    setup-Plot-Legends ;set up legends for plotting
  ]
end

to setup-Plot-Legends
    set-current-plot "Legend"
    let k 0
    while [k < num_inputs][
      create-temporary-plot-pen (item k reverse input_labels)
      set-current-plot-pen (item k reverse input_labels)
      set-plot-pen-color (item k reverse input_colors)
      set k k + 1
    ]

    set sense_names ["betaine" "hermi" "flab" "drug" "odor5" "odor6" "odor7" "odor8" "odor9" "odor10" "pain"]
    set sense_colors (lput 15 odor-color-list)
    set num_senses num-odor-types + 1
    set senses n-values num_senses [0]
    set-current-plot "Senses-Legend"
    set i 0
    while [i < num_senses][
      create-temporary-plot-pen (item i sense_names)
      set-current-plot-pen (item i sense_names)
      set-plot-pen-color (item i sense_colors)
      set i i + 1
    ]
end

;---------------------------------------------------------------------------------
;           Set Up Environment, Spawn Prey and Drug
;---------------------------------------------------------------------------------
to setup-Environment
  set Static-Environment true
  set Presentation-Mode false
  set immobilize false
  set fix-Matrix false
  set fix-Satiation 0.10
  set evapc 0.90; evaporation constant for prey odors
  set diffc 0.3 ; diffusion constant for prey odors

  ifelse member? "Sequence Learning" experiment_mode or member? "Population" experiment_mode[; changes prey locations, environment wrapping, and walls depending on experiment mode
    __change-topology true true
    set Spatial-Mapping-Enabled false
    set evapc 0.95 ;greater diffusion and evaporation constants, for larger area of effect of prey odors (larger overlap for sequences)
    set diffc 0.5
    ;set fix-Satiation 0.15
    if experiment_mode = "Prey Populations" [ ;creates randomly moving flabellina, hermissenda and drug prey
      set Static-Environment false
      create-prey flab-populate [set prey-type "flab" setxy random-xcor random-ycor]
      create-prey hermi-populate [set prey-type "hermi" setxy random-xcor random-ycor]
      create-prey drug-populate [set prey-type "drug" setxy random-xcor random-ycor]
      if Clustering = true [
        set cluster-x-coordinates [ 0 0 0 0 ]
        set cluster-y-coordinates [ 0 0 0 0 ]
        let indices range(length cluster-x-coordinates)
        (foreach indices [[k] ->
          ifelse k = 0 [set cluster-x-coordinates replace-item k cluster-x-coordinates (random-pxcor) set cluster-y-coordinates replace-item k cluster-y-coordinates (random-pycor)][
            let avg-x mean (sublist cluster-x-coordinates 0 (k))
            let avg-y mean (sublist cluster-y-coordinates 0 (k))
            set cluster-x-coordinates replace-item k cluster-x-coordinates (avg-x  + (-1 + 2 * random 2) * (Cluster-Distance + random 20))
            set cluster-y-coordinates replace-item k cluster-y-coordinates (avg-y + (-1 + 2 * random 2) * (Cluster-Distance + random 20))
          ]
        ])
        ask prey [
          let ind (position prey-type prey-types-list)
          setxy (item ind cluster-x-coordinates + random-float cluster-radius) (item ind cluster-y-coordinates + random-float cluster-radius)
        ]
      ]
    ]
    if experiment_mode = "Temporal Sequence Learning"  [
      ask Cslugs [set heading 0 setxy 0 Present-y-coord]
      ;set fix-Satiation 0.17
      set immobilize true
      set Presentation-Mode true
    ]
    if experiment_mode = "Spatial Sequence Learning"  [
      ask Cslugs [set heading 0 setxy 0 -70]
      create-prey 1 [set prey-type "flab" setxy 1 -30 set fixed 1] ;1 -20
      create-prey 1 [set prey-type "hermi" setxy 0 2 set fixed 1] ;0 34
      create-prey 1 [set prey-type "drug" setxy -1 34 set fixed 1] ;-34 -68
    ]
  ][
    set Spatial-Mapping-Enabled true
    set fix-Satiation 0.01
    ask Cslugs [set heading 30 setxy 0 0]
    __change-topology false false

    ifelse experiment_mode = "3 Source Spatial Mapping"  [
      create-prey 1 [set prey-type "hermi" setxy 11 40 set fixed 1]
      create-prey 1 [set prey-type "flab" setxy -34 -10 set fixed 1] ;-19 -23
      create-prey 1 [set prey-type "drug" setxy 47 9 set fixed 1] ;55 -36
    ][
      create-prey 1 [set prey-type "hermi" setxy 11 40 set fixed 1] ;0 34
      create-prey 1 [set prey-type "flab" setxy -41 -50 set fixed 1] ;1 -20
      create-prey 1 [set prey-type "drug" setxy 45 -7 set fixed 1] ;-34 -68
      create-prey 1 [set prey-type "p5" setxy -43 27 set fixed 1]
      ;create-prey 1 [set prey-type "p6" setxy 45 -46 set fixed 1]
      create-prey 1 [set prey-type "p7" setxy 2 -45 set fixed 1]
      ;create-prey 1 [set prey-type "p8" setxy 51 21 set fixed 1]
    ]
    if experiment_mode = "Obstacle Avoidance Learning" [ ; create wall
      ask Cslugs [set heading 150 setxy 7 50]
      let wallcoordsx (list 52 22 35 42 60 65 10 29 38 );(range 24 67 7.17);(list 52 22 33 42 60 65)
      let wallcoordsy (list 28 7  15 21 34 36 1  -5 -16 );(range 9 38 4.83);(list 28 7  14 21 34 36)
;      let wallcoordsx (list 52 22 33 42 60 65)
;      let wallcoordsy (list 28 7  14 21 34 36)
      let numpts length(wallcoordsx)
      repeat numpts [
        create-wallpts 1[setxy (item wallcount wallcoordsx) (item wallcount wallcoordsy) set wall-id count wallpts]
        set wallcount wallcount + 1
      ]
    ]
    set wallcount 0
    let wallcoordsxrange (range (-1 * (max-pxcor - 1)) (max-pxcor - 2) 5)
    let wallcoordsyrange (range (-1 * (max-pycor - 1)) (max-pycor - 1) 5)
    let numpts length(wallcoordsxrange)
    repeat numpts [
      create-wallpts 1 [setxy (item 1 wallcoordsxrange) (item wallcount wallcoordsyrange) set wall-id count wallpts]
      create-wallpts 1 [setxy (last wallcoordsxrange) (item wallcount wallcoordsyrange) set wall-id count wallpts]
      create-wallpts 1 [setxy (item wallcount wallcoordsxrange) (item 1 wallcoordsyrange) set wall-id count wallpts]
      create-wallpts 1 [setxy (item wallcount wallcoordsxrange) (last wallcoordsyrange) set wall-id count wallpts]
      set wallcount wallcount + 1
    ]
;      ask patches [
;        set odor-list n-values num-odor-types [0]
;        if (abs pxcor > max-pxcor - 5) or (abs pycor > max-pycor - 5) [set odor10 0.5] ; The WALL (of offensive odor)
;      ]
;    repeat 20 [diffuse odor10 0.1]
  ]
  ;create-color-effects 20 [set hidden? true setxy random-xcor random-ycor]
  ;ask n-of 7 color-effects [set large-color-effect 1]

  ;create-pebbles 500 [set color 32 set size 3 set shape "pebble" setxy (-70 + 2 * random max-pxcor) (-1 * max-pycor + random 20)]
  ;create-pebbles 10 [set color 32 set size 3 set shape "pebble" setxy random-xcor random-ycor]

end

;-----------------------------------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------------------------------

;;==========================================================================================================================================
;;                                                   U P D A T E    P R O C E D U R E S
;;==========================================================================================================================================


to Go
  if is-string? Screenshot-At-Ticks: and length Screenshot-At-Ticks: > 0 [export-view-at-ticks Screenshot-At-Ticks:]
  if Save-Data [write-to-file]
  if member? "Q-Learning" LEARNING_MODE [
    if ticks = 1 [set-patch-rewards]
    if LEARNING_MODE = "Q-Learning (Turn Left/Right)" [if ticks mod 5000 = 0 [clear-trails-save-view]]
    if LEARNING_MODE = "Q-Learning (Turn Approach/Avoid)" [if ticks mod 10000 = 0 [clear-trails-save-view]]
    ask Cslugs [
      if length reward-list_Q >= 500 [ ;checks if stuck
        let rsublist sublist reward-list_Q ((length reward-list_Q) - 300) (length reward-list_Q)
        if standard-deviation rsublist < 10 and mean rsublist < -12 [resetEpisode]
        if standard-deviation rsublist < 20  and mean rsublist > 7 and min rsublist > 1 [resetEpisode]
      ]
    ]
  ]

  update-prey-and-odors
  ;=================================================================================
  ;
  ;           Cslug Actions (update of Cslug variables)
  ;
  ;=================================================================================
  ask Cslugs [

    update-sensors ;updates sensor values and locations
    plot-senses
    plot-recalled-senses
    ;------------------------------------------------------;
    ;           Sets values for odor and pain sensation
    ;------------------------------------------------------;
    ;; Detecting prey and pain
    set sns_odors (map [[x1 x2] -> (x1 + x2) / 2] sns_odors_left sns_odors_right)
    set sns-pain ((sns-pain-left + sns-pain-right ) / 2)
    ;sets an upper limit for pain (via logistic function).
    set pain 10 / (1 + e ^ (- 2 * (sns-pain + spontaneous-pain) + 10 ))

    ;pain-switch will switch the signs of Reward State and Pain in Appetitive State when Pain is greater than Reward State
    ; (Effectively, this causes pain and reward state to be in reciprocal inhibition.
    ;  In the presence of enough pain, positive rewards will ease the effect of pain,
    ;  while negative rewards will exacerbate it.)
    set pain-switch 1 - 2 / (1 + e ^ (- 10 * (sns-pain - 0.2)));

    ;-----------------------------------------------------------------;
    ;           APPROACH AND AVOIDANCE BEHAVIORS
    ;=================================================================;

    ;------------------------------------------------------;
    ;    Sets positive and negative expected reward (unused)
    ;------------------------------------------------------;
    ;sets positive expected reward (based on satiation, sns-betaine, sns-hermi, sns-drug, associative value for sns-hermi, and associative value for sns-drug)
    ;set ExpReward_pos sns_betaine / (1 + (0.05 * Vh * sns_hermi) - 0.006 / Satiation) + 3.0 * Vh * sns_hermi + 8.0 * Vd * sns_drug;

    ;sets negative reward (based on pain, sns-flab, and associative value for for sns-flab)
    ;set ExpReward_neg 0.59 * Vf * sns_flab; + pain; R-

    ;------------------------------------------------------;
    ;        Handles Nutrition and Satiation
    ;------------------------------------------------------;
    handle-consumption-events ; for prey/drug consumption events

    ; sets decrease in nutrition, satiation (based only on nutrition), and incentive salience (based on positive and negative reward)
    set Nutrition Nutrition - 0.0005 * Nutrition ; Nutritional state declines with time
    ifelse Fix-var1: [set Satiation fix-satiation] [set Satiation 1 / ((1 + 0.7 * exp(-4 * Nutrition + 2)) ^ (2))]
    ;set Incentive ExpReward_pos - ExpReward_neg;

    ;-----------------------------------------------------------;
    ;        FAM Memory, Somatic Map, and Reward Calculations
    ;-----------------------------------------------------------;
    update-RewardExperience false 0.95 ;update procedure for calculating input and output of Homeostatic Reward Circuit; learning demos do not use homeostatic plasticity mechanisms
    ;decay negative and positive rewards received from prey/drug consumption
    set reward_pos 0.7 * reward_pos
    set reward_neg 0.7 * reward_neg
    set inputs (sentence (sublist sns_odors 1 9) (list sns-pain reward_pos reward_neg)) ;sensory (first 8) and reward (last 2) inputs for FAMatrix and more;
    if Spatial-Mapping-Enabled [calculate-path-integration]
    calculate-traces ;eligibility traces

    if member? "Q-Learning" LEARNING_MODE [update-state-inputs calculate-Somatic-Map-and-Incentive qlearningextension:learning]
    if LEARNING_MODE = "Rescorla-Wagner Learning Algorithm" [calculate-Somatic-Map-and-Incentive]
    if LEARNING_MODE = "Feature Association Matrix (FAM)" [
      calculate-Learning-Matrix
      calculate-Somatic-Map-and-Incentive
      reactivate-memory-of-inputs

      if experiment_mode = "Obstacle Avoidance Learning" [predefine-memory-vector] ; set up predefined memory vector for testing obstacle learning

      plot-FAMatrix
      plot-Graphs
      if Show-MemoryLabels[
        ask links with [text != "" and text != 0] [
          let dist1 [distancexy mouse-xcor mouse-ycor] of end1
          let dist2 [distancexy mouse-xcor mouse-ycor] of end2
          ifelse all-text and link-length > 1 [set label text][ifelse (dist1 + dist2) - link-length < 0.5 [set label text][set label ""]]
        ]
      ]
    ]
    ;------------------------------------------------------;
    ;      Calculate Appetitive State and Turning
    ;------------------------------------------------------;

    if LEARNING_MODE != "Q-Learning (Approach/Avoid)" [
      ; sets Appetitve State
      ;set App_State 0.01 + (1 / (1 + exp(- (0.75 * Incentive - 9 * satiation -  1.8 * Pain - 1.8 * pain-switch * RewardExperience))) + 0.1 * ((App_State_Switch - 1) * 0.5)); + 0.25
      set App_State 0.01 + (1 / (1 + exp(- (7.5 * Incentive - 8 * satiation -  0.1 * Pain - 0.1 * pain-switch * RewardExperience))) + 0.1 * ((App_State_Switch - 1) * 0.5)); + 0.25

      ; The switch for approach-avoidance
      set App_State_Switch (((-2 / (1 + exp(-100 * (App_State - 0.245)))) + 1))
    ]

    if LEARNING_MODE != "Q-Learning (Turn Left/Right)" or (LEARNING_MODE = "Q-Learning (Turn Left/Right)" and max senses > 0)[
      ;set the turning angle based on appetitive state switch and somatic map
      set turn-angle 3 * ((2 * App_State_Switch) / (1 + exp (3 * Somatic_Map)) - App_State_Switch) ; 1st constant (multiplier) was 1
      set turn-angle turn-angle + 1 * (item (length(senses_left) - 2) senses_left) ; left turn bias for walls
      ifelse force-turn = 0 [rt turn-angle][rt force-turn]
      set turn-angle-accumulation turn-angle-accumulation + turn-angle

      ; if the immobilize switch is ON, then fixes Cslug in place, but it can still turn (for testing purposes)
      ifelse immobilize = true[
        set speed 0
        set forward-movement 0
      ][
        set speed 0.5
        set forward-movement speed - (item (length(senses) - 2) senses) / 4 ; stops at walls
      ]
      fd forward-movement
    ]
  ]


  ;---------------------------------------------------------------------------------------------------
  ;                     Updates ticks (units of time), timers, and misc.
  ;---------------------------------------------------------------------------------------------------
  update-arms ;decorative effect
  drag; allow user to drag things around
  tick
  ifelse ticks < 300 [set plot-timer 0][set plot-timer plot-timer + 1] ;for graphing
  if ticks = stop_time [stop] ; definite end of an epoch of play
  if ticks > 0 and (ticks mod switch_time) = 0 [switch_on]
end



;-----------------------------------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------------------------------

;;==========================================================================================================================================
;;                                         O T H E R  U P D A T E   F U N C T I O N S
;;==========================================================================================================================================

;-----------------------------------------------------------------;
;           PREY, DRUG, WALL, AND ODOR UPDATE PROCEDURES
;=================================================================;
to update-prey-and-odors
  ;---------------------------------------------------------------------------------
  ;           Updates Prey and Drug Populations
  ;---------------------------------------------------------------------------------
  ask turtles [set non-edible 0.9 * non-edible]
  let flabs prey with [prey-type = "flab"]
  let hermis prey with [prey-type = "hermi"]
  let drugs prey with [prey-type = "drug"]
  let fauxflabs prey with [prey-type = "fauxflab"]
  ask prey[
    set shape "circle"
    set size 1
    set color item (position prey-type prey-types-list) prey-color-list
    rt -1 + random-float 2 ; random movement of prey
    ifelse Immobilize or Static-Environment [ fd 0][fd 0.02]
  ]
  if experiment_mode = "Prey Populations" [
    set Presenting ""
    create-prey flab-populate - count flabs [set prey-type "flab" setxy random-xcor random-ycor]
    if flab-populate < count flabs [ask n-of (count flabs - flab-populate) flabs [die]]
    create-prey hermi-populate - count hermis [set prey-type "hermi" setxy random-xcor random-ycor]
    if hermi-populate < count hermis [ask n-of (count hermis - hermi-populate) hermis [die]]
    ;    create-prey fauxflab-populate - count fauxflabs [set prey-type "fauxflab" setxy random-xcor random-ycor]
    ;    if fauxflab-populate < count fauxflabs [ask n-of (count fauxflabs - fauxflab-populate) fauxflabs [die]]

    if ticks > 0 and (ticks mod switch_time) = 0 and Clustering = true[ ;for Prey clustering updates
      let indices range(length cluster-x-coordinates)
      (foreach indices [[k] ->
        ifelse k = 0 [set cluster-x-coordinates replace-item k cluster-x-coordinates (random-pxcor) set cluster-y-coordinates replace-item k cluster-y-coordinates (random-pycor)][
          let avg-x mean (sublist cluster-x-coordinates 0 (k))
          let avg-y mean (sublist cluster-y-coordinates 0 (k))
          set cluster-x-coordinates replace-item k cluster-x-coordinates (avg-x  + (-1 + 2 * random 2) * (Cluster-Distance + random 20))
          set cluster-y-coordinates replace-item k cluster-y-coordinates (avg-y + (-1 + 2 * random 2) * (Cluster-Distance + random 20))
        ]
      ])
      ask prey [
        let ind (position prey-type prey-types-list)
        setxy (item ind cluster-x-coordinates + random-float cluster-radius) (item ind cluster-y-coordinates + random-float cluster-radius)
      ]
    ]
    if not Addiction_Cycle[
      create-prey drug-populate - count drugs [set prey-type "drug" setxy random-xcor random-ycor]
      if drug-populate < count drugs [ask n-of (count drugs - drug-populate) drugs [die]]
    ]
  ]
  if member? "TS" Presenting [set pticks pticks + 1 present-Temporal-Sequences] ;Present_TemporalSeq1 or Present_TemporalSeq2 [Present_TemporalSequences]

  ;---------------------------------------------------------------------------------
  ;           Updates Odors
  ;---------------------------------------------------------------------------------
  ; Initialize, deposit, diffuse, and evaporate odors
  ask prey [
    let idnum position prey-type (remove-item 2 prey-types-list)
    let pointer-target self
    ask other prey [
      let pointer-parent self
      let idnum-origin position prey-type (remove-item 2 prey-types-list)
      if (count memory-pointers with [parent = pointer-parent]) < count other prey[
        hatch-memory-pointers 1[
          set parent pointer-parent
          set targ pointer-target
          set id (list idnum-origin idnum)
          set label ""
          set size 2
          ;set shape "circle"
          set color [color] of pointer-target
          let parent-color [color] of parent
          create-link-from parent [set color parent-color]
        ]
      ]
    ]
    ifelse show-memorylabels [ ;displays learned reward values of prey/landmarks
      ifelse idnum != 2 [
        set label (word "Ri = " ([precision (item idnum Imag_Rewards) 2] of Cslug 0))
      ][
        set label (word "Rr = " ([precision (item idnum Realsense_Rewards) 2] of Cslug 0))
      ]
      ask memory-pointers [set hidden? false]
      ask links [set hidden? false]
    ][
      set label ""
      ask memory-pointers [set hidden? true]
      ask links [set hidden? true]
    ]

    set odor-list item (position prey-type prey-types-list) prey-odor-matrix
    set odor_betaine item 0 odor-list
    set odor_hermi item 1 odor-list
    set odor_flab item 2 odor-list
    set odor_drug item 3 odor-list
    set odor5 item 4 odor-list
    set odor6 item 5 odor-list
    set odor7 item 6 odor-list
    set odor8 item 7 odor-list
    set odor9 item 8 odor-list
    set odor10 item 9 odor-list
  ]

  ask wallpts [set odor10 1]
  ;; diffuse odors
  diffuse odor_betaine diffc
  diffuse odor_hermi diffc
  diffuse odor_flab diffc
  diffuse odor_drug diffc
  diffuse odor5 diffc
  diffuse odor6 diffc
  diffuse odor7 diffc
  diffuse odor8 diffc
  diffuse odor9 diffc
  diffuse odor10 diffc
  diffuse marine-colors 0.6

  ;; evaporate odors
  ask patches [
    set odor_betaine evapc * odor_betaine
    set odor_hermi evapc * odor_hermi
    set odor_flab evapc * odor_flab
    set odor_drug evapc * odor_drug
    set odor5 evapc * odor5
    set odor6 evapc * odor6
    set odor7 evapc * odor7
    set odor8 evapc * odor8
    set odor9 evapc * odor9
    set odor10 evapc * odor10
    set odor-list (list odor_betaine odor_hermi odor_flab odor_drug odor5 odor6 odor7 odor8 odor9 odor10)
    set marine-colors 0.999 * marine-colors
    recolor-patches
  ]
end

;---------------------------------------------------------------------------------
;               Recolors patches based on odor value
;=================================================================================
to recolor-patches
  ifelse show-Q-rewards [
    set pcolor scale-color red reward_Q -40 200
  ][
    let color-list (but-first odor-color-list)
    let max_odor max (but-first odor-list)
    let color_ind position max_odor (but-first odor-list)
    ;set pcolor scale-color (item color_ind color-list) max_odor 0 0.001
    let threshold 1e-7
    if color_ind = 8 [set threshold 1e-3]
    ifelse max_odor > threshold [set pcolor scale-color (item color_ind color-list) (7 + (log max_odor 10)) 0 13.5][set pcolor scale-color 105 marine-colors 0 10]
    ;ifelse max_odor > 1e-7 [set pcolor ((floor (item color_ind color-list / 10)) * 10 + 1 + 130 * max_odor)] [set pcolor scale-color 105 marine-colors 0 10]
  ]
end

;Marine color background environment (unused)
to floating-marine-colors
  ask color-effects [
    ifelse large-color-effect = 1 [set marine-colors 10 + random 5 (rt -5 + random-float 10) fd random-float 0.05]  ;ask patches in-radius 20 [set marine-colors 10 / (1 + distance myself)
    [set marine-colors 1 + random 7  (rt -5 + random-float 10) fd random-float 1.3]
  ]
  ;ask n-of (100 + random 100) patches [if ticks mod (1 + random 100) = 0 [ask patches in-radius 2 [set marine-colors marine-colors + 1]]]
end


;---------------------------------------------------------------------------------
;              Updates arm movements
;=================================================================================
to update-arms
 ask arms [
    let x-par [xcor] of parent
    let y-par [ycor] of parent
    let hd-par [heading] of parent
    let sz-par [size] of parent
    set heading hd-par
    ;setxy x-par y-par
    let arm-turn (4 + random 2) * sin(40 * ticks + random 2)
    let arm-turn2 (4 + random 2) * cos(40 * ticks + random 2)
    if id = "armo1r"[setxy (x-par + 0.4 * sz-par * sin (hd-par - 100)) (y-par + 0.4 * sz-par * cos (hd-par - 100)) set heading hd-par + 25 + arm-turn]
    if id = "armo2r"[setxy (x-par + 0.8 * sz-par * sin (hd-par + 40)) (y-par + 0.8 * sz-par * cos (hd-par + 40)) set heading hd-par + 100 - arm-turn]
    if id = "armo3r"[setxy (x-par + 0.85 * sz-par * sin (hd-par + 10)) (y-par + 0.85 * sz-par * cos (hd-par + 10)) set heading hd-par + 30 + arm-turn2]
    if id = "armo4r"[setxy (x-par - 0.8 * sz-par * sin (hd-par + 52)) (y-par - 0.8 * sz-par * cos (hd-par + 52)) set heading hd-par + 230 - arm-turn2]
    if id = "armo4l"[setxy (x-par + 0.7 * sz-par * sin (hd-par - 17)) (y-par + 0.7 * sz-par * cos (hd-par - 17)) set heading hd-par - 30 + arm-turn]
    if id = "armo3l"[setxy (x-par + 0.75 * sz-par * sin (hd-par - 90)) (y-par + 0.75 * sz-par * cos (hd-par - 90)) set heading hd-par - 160 - arm-turn]
    if id = "armo2l"[setxy (x-par + 0.8 * sz-par * sin (hd-par + 110)) (y-par + 0.8 * sz-par * cos (hd-par + 110)) set heading hd-par + 180 + arm-turn2]
    if id = "armo1l"[setxy (x-par + 0.8 * sz-par * sin (hd-par + 75)) (y-par + 0.8 * sz-par * cos (hd-par + 75)) set heading hd-par + 60 - arm-turn2]
  ]
end


;-----------------------------------------------------------------;
;                 PREY AND DRUG CONSUMPTION
;=================================================================;
to handle-consumption-events
  let target other (turtle-set prey with [non-edible < 1]) in-cone (0.4 * size) 45
  if any? target [
    let drugnum count target with [prey-type = "drug"]
    let hermnum count target with [prey-type = "hermi"]
    let flabnum count target with [prey-type = "flab"]
    let fauxflabnum count target with [prey-type = "fauxflab"]
    let pnum count target with [member? "p" prey-type]

    set Nutrition Nutrition + 0.1 * (hermnum + flabnum + fauxflabnum + drugnum + pnum)
    ;set R_hermi R_hermi - hermnum
    ;set R_flab R_flab - flabnum
    set R_drug R_drug + drug_reward * drugnum
    set reward_pos reward_pos + drugnum * 8 ;for all experiment modes except prey populations
    if experiment_mode = "Prey Populations" [
      set reward_pos reward_pos + drugnum * 8  + hermnum * 2
      set reward_neg reward_neg - flabnum * 5
    ]
    set hermcount hermcount + hermnum
    set flabcount flabcount + flabnum
    set drugcount drugcount + drugnum

    ifelse Presentation-Mode [ask target [die]][ask target  [ifelse not Static-Environment [setxy random-xcor random-ycor][set non-edible 10]]]
  ]
end

;---------------------------------------------------------------------------------
;           Updates values and positions of sensors
;=================================================================================
to update-sensors
  let me self
  update-nociceptor-position

  ;colors pain sensors to show pain value
  ask nociceptors [
    if id = "snsrOL"[
      let pain_indicator [sns-pain-left] of parent
      set color scale-color red pain_indicator 0 0.8
      if pain_indicator < 0.1 [set color lput 0 extract-rgb color]
    ]
    if id = "snsrOR"[
      let pain_indicator [sns-pain-right] of parent
      set color scale-color red pain_indicator 0 0.8
      if pain_indicator < 0.1 [set color lput 0 extract-rgb color]
    ]
  ]
  ;----------------------------------------------------------
  set odors_left [odor-list] of patch-left-and-ahead 40 (0.4 * size)
  set sns_odors_left map [x -> ifelse-value (x > 1e-7) [7 + (log x 10)][0]] odors_left

  set odors_right [odor-list] of patch-right-and-ahead 40 (0.4 * size)
  set sns_odors_right map [x -> ifelse-value (x > 1e-7) [7 + (log x 10)][0]] odors_right
  ;----------------------------------------------------------
  ;set sns-pain-left sum [painval] of (nociceptors with [id = one-of["snsrOL" "snsrUL" "snsrBL"] and parent = me])
  ;set sns-pain-right sum [painval] of (nociceptors with [id = one-of["snsrOR" "snsrUR" "snsrBR"] and parent = me])
  ;set sns-pain-caud  sum [painval] of (nociceptors with [id = one-of["snsrBL" "snsrBR" "snsrBM"] and parent = me])

  ;sensation of pain
  set sns-pain-left 0.9 * sns-pain-left
  set sns-pain-right 0.9 * sns-pain-right

end

;---------------------------------------------------------------------------------
;           Updates positions of pain sensors
;=================================================================================
to update-nociceptor-position
  ask nociceptors[
      let x-par [xcor] of parent
      let y-par [ycor] of parent
      let hd-par [heading] of parent
      let sz-par [size] of parent

      ifelse id = "snsrOL"[
        setxy (x-par + 0.4 * sz-par * sin (hd-par - 40)) (y-par + 0.4 * sz-par * cos (hd-par - 40))
      ][
       ifelse id = "snsrOR"[
         setxy (x-par + 0.4 * sz-par * sin (hd-par + 40)) (y-par + 0.4 * sz-par * cos (hd-par + 40))
       ][
        ifelse id = "snsrUL"[
          setxy (x-par + 0.3 * sz-par * sin (hd-par - 100)) (y-par + 0.3 * sz-par * cos (hd-par - 100))
        ][
         ifelse id = "snsrUR"[
           setxy (x-par + 0.3 * sz-par * sin (hd-par + 100)) (y-par + 0.3 * sz-par * cos (hd-par + 100))
         ][
          ifelse id = "snsrBL"[
            setxy (x-par + 0.35 * sz-par * sin (hd-par - 150)) (y-par + 0.35 * sz-par * cos (hd-par - 150))
          ][
           ifelse id = "snsrBR"[
             setxy (x-par + 0.35 * sz-par * sin (hd-par + 150)) (y-par + 0.35 * sz-par * cos (hd-par + 150))
           ][
             setxy (x-par + 0.46 * sz-par * sin (hd-par - 180)) (y-par + 0.46 * sz-par * cos (hd-par - 180))
           ]
          ]
         ]
        ]
       ]
      ]
    ]

end


;---------------------------------------------------------------------------------
;           Somatic Map and Incentives Calculations (Function)
;=================================================================================
;---------------------------------------------------------------------------------
to calculate-Somatic-Map-and-Incentive
  ;let betaine_reward 1
  let odor10_reward -2.5
  let pain_reward -1.5
  set Realsense_Rewards (sentence (sublist Direct_Rewards 0 (num_inputs - 3)) (list odor10_reward pain_reward))
  let Somatic_Map_realsenses ( lput sns-pain but-first sns_odors )
  let Somatic_Map_senses_left ( lput sns-pain-left but-first sns_odors_left )
  let Somatic_Map_senses_right ( lput sns-pain-right but-first sns_odors_right )

  set Imag_Incentives (map [[reward sense] -> (reward) * sense] Imag_Rewards imag_senses)
  set Incentives (map [[reward sense] -> (reward) * sense] Realsense_Rewards Somatic_Map_realsenses)

  ;let Somatic_Map_senses (map [[x1 x2] -> (x1 + x2)] Somatic_Map_realsenses imag_senses)
  let Somatic_Map_incentives (map [[x1 x2] -> (abs x1 + abs x2) / 10] Incentives Imag_Incentives)
  set Somatic_Map_Factors map [x -> 2 * x - sum (Somatic_Map_incentives)] Somatic_Map_incentives ;; Exponent variables for somatic map, which basically determine interaction and "priority" of the sensations
  let last_index (length Somatic_Map_Factors - 1)
  ;set Somatic_Map_Factors replace-item (last_index - 1) Somatic_Map_Factors (item (last_index - 1) Somatic_Map_realsenses)
  set Somatic_Map_Factors replace-item last_index Somatic_Map_Factors pain

  let indices range (length Somatic_Map_incentives)
  (foreach indices Somatic_Map_senses_left Somatic_Map_senses_right Realsense_Rewards imag_senses_left imag_senses_right Imag_Rewards Somatic_Map_Factors [[n sns_left sns_right real_sns_r im_sns_left im_sns_right im_sns_r C] ->
    set Somatic_Map_Sigmoids replace-item n Somatic_Map_Sigmoids (((1 + real_sns_r) * (sns_left - sns_right) + 20 * (1 + im_sns_r) * (im_sns_left - im_sns_right)) / (1 + exp (-30 * C))) ])

  ifelse Fix-var3: [set Somatic_Map fix-SomaticMap][set Somatic_Map -1 * (sum Somatic_Map_Sigmoids)]
end



;---------------------------------------------------------------------------------
;           Homeostatic Reward Circuit Calculations (Function)
;=================================================================================
to update-RewardExperience [homeostatic-change? d-decay]

  ;sets reward inputs, which decay over time
  set R_hermi 0.98 * R_hermi
  set R_flab 0.98 * R_flab
  set R_drug d-decay * R_drug

  ;Sets Reward Input to neuron M, with a baseline activity of M0
  set R (W1 * R_drug + W2 * IN + W4 * R_hermi + W5 * R_flab + M0)
  ;Positive feedback loop for reward input
  set IN (W2 * R)
  ;Response of neuron M, based on the dynamic synaptic weight W3 and Reward Input (R)
  set M (W3 * R)
  ;Change in W3 depends on neuron M activity, neuron M baseline (M0), and Reward Input (R)
  if homeostatic-change? [
    set dW3 ((M0 - M) / R) / 1000
    set W3 (W3 + dW3)
  ]

  ;sets Reward State value as a logistic function of neuron M activity minus its baseline. Basically indicates how much neuron M activity differs from baseline.
  ; (Reward State is the output of the Homeostatic Reward Circuit (HRC) to Appetitive State)
  ifelse Fix-var2: [set RewardExperience Fix-RewardExp][set RewardExperience -15 + 30 / (1 + e ^ (-(M - M0)))]

end

; H0 = baseline, Wt1 = current value of homeostatic synaptic weight (at time t1), tau = time constant
to-report homeostat [Input H0 Wt1 tau]
  if Input = 0 [set Input 0.1]
  let Ht1 Wt1 * Input
  let Wt2 Wt1 + ((H0 - Ht1) / (Input)) / tau
  let Ht2 Wt2 * Input
  report (list Wt2 Ht2) ;
end


;-----------------------------------------------------------------------------------------;
;=========================================================================================;
;
;               FEATURE ASSOCIATION MATRIX CALCULATION AND PLOTTING FUNCTIONS
;
;=========================================================================================;

to calculate-traces
  let old-traces traces
  let indices range (length inputs)
  (foreach indices [[n] ->
    ifelse n < num_inputs - 2 [
      let trace item n traces
      let others remove-item n inputs
      ;For temporal sequence learning, trace decays without path integration (slitherometer), for mapping trace is maintained in absence of other inputs; decreases with other inputs
      ifelse item n inputs > 1e-7 [set trace 0.7 + 0.3 / (1 + exp(-3 * (item n inputs) + 7))] [set trace (1.94 * (0.5 - speed) * trace) + sign2 slitherometer * (trace - 0.03 * trace * sum others)]
      set traces replace-item n traces trace
        ][set traces replace-item n traces (item n inputs)]
    ])
  set trace-changes (map [[trt1 trt0] -> trt1 - trt0] traces old-traces)
end


to calculate-Learning-Matrix
  ; each association is between two inputs (input-i and input-j)
  set i 0
  set j 0
  set Incentive 0
  while [i < num_inputs] [
    set ImagReward_i 0
    set DirectReward_i 0
    while [j < num_inputs] [
      if i != j[
        if LEARNING_MODE = "Feature Association Matrix (FAM)" [
          if not fix-Matrix [
            calculate-FAMatrix-element    ; calculates strength, order, and memory vector for each association
            assign-Reward-element         ; assigns expected reward value for each association
                                          ; calculates (predicted) vectors for pairwise associations that haven't been experienced yet, condition on max trace introduces slight delay, to ensure reward vals are updated first
            if Spatial-Mapping-Enabled and max traces <= 0.9 [assign-Vector-element]
          ]
          calculate-Incentive-Element   ; calculates contribution to Incentive for each association
        ]
        if LEARNING_MODE = "Rescorla-Wagner Learning Algorithm" [
          calculate-Rescorla-Wagner-element
        ]
      ]
      set j j + 1
    ]
    if i < num_inputs - 3 [
      set Imag_Rewards replace-item i Imag_Rewards ImagReward_i
      set Direct_Rewards replace-item i Direct_Rewards DirectReward_i
    ]
    set i i + 1
    set j 0
  ]
  set i 0
end


; Calculates strength, order, and memory vector for each association
to calculate-FAMatrix-element
  let post-reward-landmark false
  let tracei item i traces
  let tracej item j traces
  let inputi item i inputs
  let inputj item j inputs
;        if i = num_inputs - 2 [set tracei reward_pos]
;        if i = num_inputs - 1 [set tracei reward_neg]
;        if j = num_inputs - 2 [set tracej reward_pos]
;        if j = num_inputs - 1 [set tracej reward_neg]
  let cross-mult 4
  let thresh 0.01 ;was 0.1, now lower due to indefinite traces
  let cross (abs(tracei) * abs(tracej))
  let diff (abs(tracej) - abs(tracei))
  let tsum (abs(tracei) + abs(tracej))
  let max_trace max (list abs(tracei) abs(tracej))
  ifelse i >= (num_inputs - 2) or j >= (num_inputs - 2) [
    matrix:set FAMatrix_timelags i j 0
    let noreward_decay 0
    if i < num_inputs - 2 [set noreward_decay sign2 (inputi - 1) * sign2 (1 - inputj)]
    if j < num_inputs - 2 [set noreward_decay sign2 (inputj - 1) * sign2 (1 - inputi)]
    matrix:set FAMatrix_cross-A i j (matrix:get FAMatrix_cross-A i j) / (1 + noreward_decay / 50)
    if (i = 10 or j = 10) and reward_pos < 3 [ set tsum 0]
    if (i = 11 or j = 11) and reward_neg > -3 [ set tsum 0]
    set cross-mult 0.3
  ][
;    let k 0
;    while [k < num_inputs and not post-reward-landmark ][
;      if matrix:get FAMatrix_strengths i j > 0.99 [
;        if matrix:get FAMatrix_diff-A i j < -0.001 and matrix:get FAMatrix_timelags j k = 0 and matrix:get FAMatrix_rewards j k > 1 [set post-reward-landmark true print true]
;        if matrix:get FAMatrix_diff-A i j  > 0.001 and matrix:get FAMatrix_timelags i k = 0 and matrix:get FAMatrix_rewards i k > 1 [set post-reward-landmark true print true]
;      ]
;      set k k + 1
;    ]
;    set k 0
    ;**************
    matrix:set FAMatrix_diff-A i j (matrix:get FAMatrix_diff-A i j) +  (1 / (1 + exp(3 * matrix:get FAMatrix_rewards i j - 6))) * tsum * (diff - (matrix:get FAMatrix_diff-A i j))     ;accumulator function based on difference of traces (and product of traces)
    let ord-factor 2
    ;if post-reward-landmark [set ord-factor -1 * ord-factor]
    matrix:set FAMatrix_timelags i j ord-factor * matrix:get FAMatrix_diff-A i j
    ;matrix:set FAMatrix_diff-A i j (matrix:get FAMatrix_diff-A i j) +  (1 / (1 + exp(3 * matrix:get FAMatrix_rewards i j - 6))) * cross * (diff - (matrix:get FAMatrix_diff-A i j))   ;accumulator function based on difference of traces (and product of traces)
    ;matrix:set FAMatrix_timelags i j (2 / (1 + exp(-(10 * (matrix:get FAMatrix_diff-A i j)))) - 1)

    if Spatial-Mapping-Enabled and cross > 0.15  [ ;>0.4  ;and (max list tracei tracej) > 0.8
      let vsign 0
      if matrix:get FAMatrix_timelags i j < 0 [set vsign 1]
      ;if post-reward-landmark [set vsign (vsign + 1) mod 2]
      let vdist_prev matrix:get FAMatrix_vdist i j
      let vdir_prev matrix:get FAMatrix_vdir i j
      ;if vdist_prev = 0 and matrix:get FAMatrix_rewards i j > 1e-3 [set vsign vsign + 1]
      matrix:set FAMatrix_vdir i j  item 0 vsum - vsign * 180
      matrix:set FAMatrix_vdist i j item 1 vsum

;      ifelse vdist_prev = 0 [
;        matrix:set FAMatrix_vdir i j  item 0 vsum - vsign * 180
;        matrix:set FAMatrix_vdist i j item 1 vsum
;      ][
;        let v_avg average-vectors (list vdir_prev vdist_prev) (list (item 0 vsum - vsign * 180) (item 1 vsum) )
;        matrix:set FAMatrix_vdir i j  item 0 v_avg
;        matrix:set FAMatrix_vdist i j item 1 v_avg
;      ]

    ]
  ]
  matrix:set FAMatrix_cross-A i j (matrix:get FAMatrix_cross-A i j) + (0.001 * matrix:get FAMatrix_rewards i j + cross-mult * cross - thresh) * (tsum)  ;accumulator function based around product of traces (and product threshold and sum)
  matrix:set FAMatrix_strengths i j  1 / (1 + exp(-2 * (matrix:get FAMatrix_cross-A i j) + 6))
  matrix:set FAMatrix_cross-A i j (matrix:get FAMatrix_cross-A i j) + (matrix:get FAMatrix_strengths i j - matrix:get FAMatrix_cross-A i j) / 10000   ;accumulator function is slowly decayed, to limit growth
end



; Assign expected rewards (but not orders or strengths) through a series of summations based on elements' orders and strengths
to assign-Reward-element
  ifelse i > (num_inputs - 3) or j > (num_inputs - 3) [
    ;let strsign sign2 (matrix:get FAMatrix_strengths i j - 0.1)
    let strsign 1.01 / (1 + exp(-20 * (matrix:get FAMatrix_strengths i j) + 8))
    if (i = num_inputs - 2) or (j = num_inputs - 2) [matrix:set FAMatrix_rewards i j (10 * strsign)]
    if (i = num_inputs - 1) or (j = num_inputs - 1) [matrix:set FAMatrix_rewards i j (-10 * strsign)]
    ;if (i = num_inputs - 2 and item i inputs > 1e-7 ) or (j =  num_inputs - 2 and item j inputs > 1e-7 ) [matrix:set FAMatrix_rewards i j (10 * matrix:get FAMatrix_strengths i j)]
    ;if (i = num_inputs - 1  and item i inputs > 1e-7 ) or (j = num_inputs - 1 and item j inputs > 1e-7)  [matrix:set FAMatrix_rewards i j (-10 * matrix:get FAMatrix_strengths i j)]
  ][
    let k 0
    let s-factor 1
    let post-reward-landmark false
    let cross abs(item i traces) * abs(item j traces) ; 0.01
    let diff abs(item j traces) - abs(item i traces) ; 0.001
    if cross > 0.01[
      while [k < num_inputs and not post-reward-landmark ][
        ifelse matrix:get FAMatrix_rewards i j <= 1 [
          if diff < -0.001 and matrix:get FAMatrix_timelags j k = 0 and matrix:get FAMatrix_rewards j k > 1 [set post-reward-landmark true]
          if diff > 0.001 and matrix:get FAMatrix_timelags i k = 0 and matrix:get FAMatrix_rewards i k > 1 [set post-reward-landmark true]
        ][
          if matrix:get FAMatrix_strengths i j > 0.99 [
            if diff < -0.001 and matrix:get FAMatrix_timelags j k = 0 and matrix:get FAMatrix_rewards j k > 1 [set post-reward-landmark true ]
            if diff > 0.001 and matrix:get FAMatrix_timelags i k = 0 and matrix:get FAMatrix_rewards i k > 1 [set post-reward-landmark true]
          ]
        ]
        ;if matrix:get FAMatrix_timelags k i = 0 and matrix:get FAMatrix_rewards i k > 1 [set reward-landmark-neighbor true print (word "ki" k i)]
        ;if matrix:get FAMatrix_timelags k j = 0 and matrix:get FAMatrix_rewards i k > 1 [set reward-landmark-neighbor true print (word "kj" k j)]
        set k k + 1
      ]
    ]
    set k 0
    if post-reward-landmark [set s-factor 0.01] ;0.3
    let forward-reward 0
    let backward-reward 0
    let strength 0.75 * matrix:get FAMatrix_strengths i j ;******
    let strength-sig 0.7 / (1 + exp(-10 * (matrix:get FAMatrix_strengths i j) + 8))

    ifelse matrix:get FAMatrix_timelags i j >= 0 [  ; if input2 follows/coincides with input1
      let row_r matrix:get-row FAMatrix_rewards j
      let row_tl matrix:get-row FAMatrix_timelags j
      let row_length length row_r
      set k 0
      while [k < row_length] [
        if (item k row_tl) >= 0 [set forward-reward forward-reward + item k row_r]
        set k k + 1
      ]
      set k 0
      let col_r matrix:get-column FAMatrix_rewards i
      let col_tl matrix:get-column FAMatrix_timelags i
      let col_length length col_r
      while [k < col_length] [
        if (item k col_tl) >= 0 [set backward-reward backward-reward + item k col_r]
        set k k + 1
      ]
      set k 0
      ;set forward-reward sum [reward] of combos with [input1 = my-input2 and timelag >= 0]
      ;set backward-reward sum [reward] of combos with [input2 = my-input1 and timelag >= 0]
      matrix:set FAMatrix_rewards i j s-factor * (strength) * (forward-reward) ;0.5*
    ][ ;else if input1 follows/coincides with input2
      let col_r matrix:get-column FAMatrix_rewards i
      let col_tl matrix:get-column FAMatrix_timelags i
      let col_length length col_r
      set k 0
      while [k < col_length] [
        if (item k col_tl) <= 0 [set backward-reward backward-reward + item k col_r]
        set k k + 1
      ]
      set k 0
      let row_r matrix:get-row FAMatrix_rewards j
      let row_tl matrix:get-row FAMatrix_timelags j
      let row_length length row_r

      while [k < row_length] [
        if (item k row_tl) <= 0 [set forward-reward forward-reward + item k row_r]
        set k k + 1
      ]
      set k 0
      ;set backward-reward sum [reward] of combos with [input2 = my-input1 and timelag <= 0]
      ;set forward-reward sum [reward] of combos with [input1 = my-input2 and timelag <= 0]
      matrix:set FAMatrix_rewards i j s-factor * (strength) * (backward-reward) ;0.5*
    ]
  ]
end

; Calculates contribution to Incentive for each association
to calculate-Incentive-element

  let order matrix:get FAMatrix_timelags i j
  let expectedReward matrix:get FAMatrix_rewards i j
  if order >= 0 and i < num_inputs - 3[
    let inputi item i inputs
    let inputj item j inputs
    let inputiL item i inputs_left
    let inputiR item i inputs_right
    let inputjL item j inputs_left
    let inputjR item j inputs_right
    if j < num_inputs - 2[
      let vdistance matrix:get FAMatrix_vdist i j
      ifelse vdistance > 0 [
        set ImagReward_i ImagReward_i + (expectedReward / (vdistance + 1))
      ][
        let input_thresh 0.3 / satiation
        let input_factor 0.1
        ; With no distance/direction info, agent navigates via Overlaps between landmarks: it will be "pushed" from the current landmark to next one in the sequence
        ;set ImagReward_i ImagReward_i + expectedReward * input_factor * (inputi + inputj) * (input_thresh - order * inputi) * (input_thresh + order * inputj) / (num_inputs ^ 2)
        set ImagReward_i ImagReward_i + expectedReward * input_factor * (inputiL + inputjL) * (input_thresh - order * inputiL) * (input_thresh + order * inputjL) / (num_inputs ^ 2)
        set ImagReward_i ImagReward_i + expectedReward * input_factor * (inputiL + inputjR) * (input_thresh - order * inputiL) * (input_thresh + order * inputjR) / (num_inputs ^ 2)
        set ImagReward_i ImagReward_i + expectedReward * input_factor * (inputiR + inputjR) * (input_thresh - order * inputiR) * (input_thresh + order * inputjR) / (num_inputs ^ 2)
        set ImagReward_i ImagReward_i + expectedReward * input_factor * (inputiR + inputjL) * (input_thresh - order * inputiR) * (input_thresh + order * inputjL) / (num_inputs ^ 2)
      ]
      set Incentive Incentive + 3 * ImagReward_i
    ]
    if j >= num_inputs - 2[
      set DirectReward_i DirectReward_i + 5 * expectedReward / (num_inputs ^ 2)
      set Incentive Incentive + 2.5 * DirectReward_i * inputi
    ]
  ]
end

to calculate-Rescorla-Wagner-element
  if i < num_inputs - 3[
    let inputi item i inputs
    let inputj item j inputs
    set strengths_RW_i item i strengths_RW
    if j >= num_inputs - 2 [ ;if neg or pos reward is encountered at the same time as a strong sensory signal, update associative strengths via Rescorla-Wagner Algorithm
      if inputi > 3 and inputj > 1 [
        let reward-sign (sign-thresh j  (num_inputs - 2) 1 -1)
        set strengths_RW_i strengths_RW_i + alpha_RW * beta_RW * (reward-sign * lambda_RW - strengths_RW_i)
      ]
      if inputi > 4 and inputj < 0.01 [
        set strengths_RW_i strengths_RW_i + (alpha_RW / 1000) * beta_RW * (0 - strengths_RW_i) ;slow extinction
      ]
      set DirectReward_i 2.5 * strengths_RW_i
      set Incentive Incentive + 2.5 * DirectReward_i * inputi
    ]
    set strengths_RW replace-item i strengths_RW strengths_RW_i
  ]
end



; Assign vectors (but not orders or strengths) through "imagination"/additional path integrations
to assign-Vector-element
if i != j and i < (num_inputs - 3) and j < (num_inputs - 3)[
    let tl_ij matrix:get FAMatrix_timelags i j
    let vec_ij (list (matrix:get FAMatrix_vdir i j) (matrix:get FAMatrix_vdist i j))
    let k 0
    while [k < (num_inputs - 3)] [
      let tl_ik matrix:get FAMatrix_timelags i k
      let vec_ik (list (matrix:get FAMatrix_vdir i k) (matrix:get FAMatrix_vdist i k))
      let tl_jk matrix:get FAMatrix_timelags j k
      let vec_jk (list (matrix:get FAMatrix_vdir j k) (matrix:get FAMatrix_vdist j k))
      let vec_jk_update [0 0]
      ;if no association/imagined association between inputs j and k has been formed yet, then "imagine" it! ;matrix:get FAMatrix_vdir j k = 0
      if j != k and (matrix:get FAMatrix_rewards j k < 1e-3 ) and matrix:get FAMatrix_rewards i j >= 1e-3 and matrix:get FAMatrix_rewards i k >= 1e-3 [
        set vec_jk_update subtract-vectors vec_ik vec_ij
        ;if tl_ij * tl_ik > 0 [set vec_jk_update subtract-vectors vec_ij vec_ik] ;if they have the same sign, keep order then subtract vectors
        ;if tl_ij * tl_ik < 0 [set vec_jk_update subtract-vectors vec_ik vec_ij] ;if they have opposite signs, flip order then subtract vectors
        ;matrix:set FAMatrix_rewards j k  (matrix:get FAMatrix_rewards i j + matrix:get FAMatrix_rewards i k) ;imagine the reward
        ;matrix:set FAMatrix_rewards k j  (matrix:get FAMatrix_rewards i j + matrix:get FAMatrix_rewards i k) ;imagine the reward
        set vec_jk average-vectors vec_jk vec_jk_update
        matrix:set FAMatrix_vdir j k item 0 vec_jk  ;**************
        matrix:set FAMatrix_vdist j k item 1 vec_jk ;**************
      ]
      set k k + 1
  ]
]
end


to calculate-path-integration
  set slitherometer slitherometer + forward-movement
  if slitherometer > 0 [
    ;set vsum sum-vectors ( list vsum (list turn-angle-accumulation forward-movement))
    set vsum sum-vectors ( list vsum (list heading forward-movement))
  ]
  let max_trace max traces
  let max_trace_change item (position max_trace traces) trace-changes
  if not member? "Q-Learning" LEARNING_MODE and not QL-minimal-states?[   ; don't reset when doing minimal QL states
    if max_trace >= 0.90 [;**********
      if max_trace_change < -0.01 [set vsum [0 0]] ;reset vsum near center of odor landmark/dropoff
      set detour-vector [0 0]
      set correction-vector [0 0]
      set vseq_temp [[0 0]]
      set vseq_count 0
    ]
  ]
  let H Homeostat turn-angle HD0 HDWeight HDtau
  set HDWeight item 0 H
  set HDOut item 1 H
end


to reactivate-memory-of-inputs
  set lsns_vec (list (heading - sensor_angle) HLB)
  set rsns_vec (list (heading + sensor_angle) HLB)
  set inputs_left (sentence (sublist sns_odors_left 1 9) (list sns-pain-left reward_pos reward_neg))
  set inputs_right (sentence (sublist sns_odors_right 1 9) (list sns-pain-right reward_pos reward_neg))
  set i 0
  set j 0
  while [i < num_inputs] [
    while [j < num_inputs] [
      if i != j and i < (num_inputs - 3) and j < (num_inputs - 3)[
        let inputi item i inputs
        let inputiL item i inputs_left
        let inputiR item i inputs_right
        let inputj item j inputs
        let inputjL item j inputs_left
        let inputjR item j inputs_right
        let tracei item i traces
        let tracej item j traces
        let accumulated_imag_j item j imag_senses_accumulators
        let vdist matrix:get FAMatrix_vdist i j
        let vdir matrix:get FAMatrix_vdir i j
        let vdestination (list vdir vdist)
        let error-vector subtract-vectors vdestination vsum
        let evdir item 0 error-vector
        let evdist item 1 error-vector
        let strength matrix:get FAMatrix_strengths i j
        let reward matrix:get FAMatrix_rewards i j
        let order matrix:get FAMatrix_timelags i j
        let post-reward-landmark false
        let k 0
        if matrix:get FAMatrix_strengths i j > 0.99 and experiment_mode = "5 Source Spatial Mapping"[ ;check for post-reward-landmark
          while [k < num_inputs and not post-reward-landmark][
            if matrix:get FAMatrix_diff-A i j < -0.001 and matrix:get FAMatrix_timelags j k = 0 and matrix:get FAMatrix_rewards j k > 1 [set post-reward-landmark true ]
            if matrix:get FAMatrix_diff-A i j  > 0.001 and matrix:get FAMatrix_timelags i k = 0 and matrix:get FAMatrix_rewards i k > 1 [set post-reward-landmark true ]
            set k k + 1
          ]
        ]
        set k 0
        ;let distfactor min (list (precision vdist 0)  1) ; 1 if vdist >= 1, 0 otherwise
        ; if path integration is not enabled, agent navigates via Overlaps between landmarks (no distance info),
        ;it will be "pushed" from the current landmark to next one in the sequence (see calculate-Incentive-element)
        ifelse vdist = 0 [
          if order > 0 [
            set imag_senses_left replace-item i imag_senses_left (item i imag_senses_left + (precision strength 0) * inputiL / 50)
            set imag_senses_right replace-item i imag_senses_right (item i imag_senses_right + (precision strength 0) * inputiR / 50)
          ]
        ][
          ;if path integration is enabled, (error) memory vector is converted into "imagined" activation of left/right sensors to orient towards next landmark

          if (not post-reward-landmark and order > 0 and tracei > 0.5 and accumulated_imag_j < 350) or experiment_mode = "Obstacle Avoidance Learning" [ ; ******** If sense recall is high over a long time (can't find landmark), terminate it
            set left_dist item 1 subtract-vectors error-vector lsns_vec
            set right_dist item 1 subtract-vectors error-vector rsns_vec
            set imag_senses_left replace-item j imag_senses_left (item j imag_senses_left + 10 * strength * tracei * (1 / (left_dist + 1)  )) ;********** * (10 / (accumulated_imag_j + 1))
            set imag_senses_right replace-item j imag_senses_right (item j imag_senses_right + 10 * strength * tracei * (1 / (right_dist + 1) ))
          ]
        if  (post-reward-landmark and order < 0 and tracei > 0.5 and accumulated_imag_j < 350)[
            set left_dist item 1 subtract-vectors error-vector lsns_vec
            set right_dist item 1 subtract-vectors error-vector rsns_vec
            set imag_senses_left replace-item j imag_senses_left (item j imag_senses_left + 10 * strength * tracei * (1 / (left_dist + 1)  )) ;********** * (10 / (accumulated_imag_j + 1))
            set imag_senses_right replace-item j imag_senses_right (item j imag_senses_right + 10 * strength * tracei * (1 / (right_dist + 1) ))
          ]
        ]
        ;set imag_senses replace-item j imag_senses (((item j imag_senses_left) + (item j imag_senses_right) ) / 2)  ;**********
        let imageL_j item j imag_senses_left
        let imageR_j item j imag_senses_right
        if vdestination != [0 0] and abs(imageL_j + imageR_j)> 2.0[
          ifelse abs(imageL_j - imageR_j) > 0.05 [ ;if there is significant deviation from memory vector, split memory vector into detour and correction vectors
            if correction-vector != [0 0] [set vseq_count vseq_count + 1    set vseq_sum sum-vectors vseq_temp    set vseq_temp insert-item vseq_count vseq_temp []     set correction-vector [0 0]]
            set detour-vector vsum
            set vseq_temp replace-item vseq_count vseq_temp detour-vector
          ][
            if detour-vector != [0 0] [set vseq_count vseq_count + 1   set vseq_sum sum-vectors vseq_temp     set vseq_temp insert-item vseq_count vseq_temp []     set detour-vector [0 0]]
            if vseq_count > 0 [
              set correction-vector subtract-vectors vsum vseq_sum
              set vseq_temp replace-item vseq_count vseq_temp correction-vector]
          ]
          set FAMatrix_vseq set-element FAMatrix_vseq i j vseq_temp
        ]
      ]
      set j j + 1
    ]
    set i i + 1
    set j 0
  ]
  set imag_senses (map [[x1 x2] -> (x1 + x2) / 2] imag_senses_left imag_senses_right) ;*******
  set imag_senses_accumulators (map [[x1 x2] -> 0.99 * (x1 + x2)] imag_senses_accumulators imag_senses)
  set imag_senses_left (map [[x1] -> 0.90 * x1] imag_senses_left)
  set imag_senses_right (map [[x1] -> 0.90 * x1] imag_senses_right)

end


; set up predefined memory vector for testing navigation around wall
to predefine-memory-vector
  if ticks = 1 [

    matrix:set FAMatrix_rewards 2 9 10
    matrix:set FAMatrix_rewards 9 2 10
    matrix:set FAMatrix_cross-A 2 9 100
    matrix:set FAMatrix_cross-A 9 2 100

    matrix:set FAMatrix_vdir 0 2 143.61564818416412
    matrix:set FAMatrix_vdist 0 2 70.80254232723568
    matrix:set FAMatrix_vdir 2 0 323.61564818416412
    matrix:set FAMatrix_vdist 2 0 70.80254232723568

    matrix:set FAMatrix_cross-A 0 2 100
    matrix:set FAMatrix_cross-A 2 0 100
    matrix:set FAMatrix_diff-A 0 2 10
    matrix:set FAMatrix_diff-A 2 0 -10
    matrix:set FAMatrix_rewards 0 2 10
    matrix:set FAMatrix_rewards 2 0 10
  ]
end


to plot-FAMatrix
  set-current-plot "Feature Association Matrix"
  ;mark the Sense_X, Sense_Y choice with a yellow frame on the matrix
  create-temporary-plot-pen (word Sense_X Sense_Y "mark")
  set-current-plot-pen (word Sense_X Sense_Y "mark")
  set-plot-pen-mode 2
  set-plot-pen-color yellow
  let xc (Sense_X + 1)
  let yc (Sense_Y + 1)
  plotxy (xc + 0.25) (yc + 0.25)
  plotxy (xc - 0.25) (yc - 0.25)
  plotxy (xc + 0.25) (yc - 0.25)
  plotxy (xc - 0.25) (yc + 0.25)

  if ticks mod 50 = 0 [clear-plot]
  set-plot-x-range 0 (num_inputs + 1)
  set-plot-y-range 0 (num_inputs + 1)
  set i 0
  set j 0
  while [i < num_inputs] [
    create-temporary-plot-pen (item i input_labels)
    set-current-plot-pen (item i input_labels)
    set-plot-pen-mode 2
    plotxy 0.7 (i + 1)
    plotxy 0.6 (i + 1)
    plotxy 0.5 (i + 1)
    plotxy (i + 1) 0.7
    plotxy (i + 1) 0.6
    plotxy (i + 1) 0.5
    set-plot-pen-color (item i input_colors)

    while [j < num_inputs] [
      if show-memorylabels and Spatial-Mapping-Enabled [Draw-Memory-Pointers]
      set xc (i + 1)
      set yc (j + 1)
      create-temporary-plot-pen (word i j)
      set-current-plot-pen (word i j)
      set-plot-pen-mode 2
      plotxy xc yc
      let coorddisp n-values 8 [ cdd -> (0.2 - 0.05 * cdd) ]
      let num_disp length coorddisp
      let k 0
      let l 0
      while [k < num_disp] [
        while [l < num_disp] [
          plotxy (xc + item k coorddisp) (yc + item l coorddisp)
          set l l + 1
        ]
        set k k + 1
        set l 0
      ]

      let plotcolor gray

      if show-FAMatrix = "strengths" [let strength matrix:get FAMatrix_strengths i j set plotcolor scale-color white strength -0.3 1]
      if show-FAMatrix = "rewards" [let reward matrix:get FAMatrix_rewards i j set plotcolor scale-color red reward -1 10]
      if show-FAMatrix = "time-lags" [
        let timelag matrix:get FAMatrix_timelags i j
        if timelag > 0 [set plotcolor scale-color yellow timelag -1 3]
        if timelag < 0 [set plotcolor scale-color blue timelag  1 -3]
        if timelag = 0 [set plotcolor gray]
      ]
      if show-FAMatrix = "vectors" [
        set-plot-pen-color red
        let radius 0.2 * (matrix:get FAMatrix_vdist i j) / 100
        let angle matrix:get FAMatrix_vdir i j
        plotxy xc yc
        set coorddisp n-values 4 [ cdd -> (radius * cdd / 8) ]
        set num_disp length coorddisp
        set k 0
        set l 0
        while [k < num_disp] [
          while [l < num_disp] [
            plotxy (xc + item k coorddisp * sin angle) (yc + item l coorddisp * cos angle)
            plotxy (xc - item k coorddisp * sin angle) (yc - item l coorddisp * cos angle)
            set l l + 1
          ]
          set k k + 1
          set l 0
          set plotcolor 1
        ]
      ]
      ifelse i = j [set-plot-pen-color 1] [set-plot-pen-color plotcolor]
      set j j + 1
    ]
    set i i + 1
    set j 0
  ]
  set-plot-background-color black
end

to draw-memory-pointers
  let mi i
  let mj j
  let vdir matrix:get FAMatrix_vdir i j
  let vdist matrix:get FAMatrix_vdist i j
  let strength matrix:get FAMatrix_strengths i j
  let order matrix:get FAMatrix_timelags i j
  let reward matrix:get FAMatrix_rewards i j
  ask memory-pointers with [id = (list mi mj)] [
    let pointer-parent self
    let target [patch-at-heading-and-distance vdir vdist] of parent
    if target != nobody[
      move-to target
      set heading vdir
      ask my-in-links [
        set mdist vdist
        set mdir vdir
        set mstr strength
        set mord order
        set mrew reward
        set text (word "S=" (precision strength 1) ", O=" (precision order 1) ", R=" (precision reward 1))
      ]
    ]
  ]
  if experiment_mode = "Obstacle Avoidance Learning" [ ;Draw out vector sequences for this mode
    let vseq item i (item j FAMatrix_vseq)
    let vseq_id (word (round-list vseq 0))
    let vseq_num length (round-list vseq 0)
    let vseq_pointers memory-pointers with [member? (word "vseq" mi mj) id]
    ask memory-pointers with [member? (word "vseq" mi mj) id and not member? vseq_id id] [set dcount dcount + 1 die]
    let vcount 1
    if vseq != [0 0] and count vseq_pointers < vseq_num [
      repeat (vseq_num - count vseq_pointers) [
        hatch-memory-pointers 1 [
          set size 2
          set id (word "vseq" mi mj (word round-list vseq 0) vcount)
          set parent one-of memory-pointers with [id = (list mi mj) and not member? "vseq" id]
          if vcount > 1 [set parent one-of memory-pointers with [id = (word "vseq" mi mj (word round-list vseq 0) (vcount - 1))]]
          set vdir item 0 (item (vcount - 1) vseq)
          set vdist item 1 (item (vcount - 1) vseq)
          if parent != nobody [
            let target [patch-at-heading-and-distance vdir vdist] of parent
            pen-up
            if target != nobody[
              move-to target
              set heading vdir
            ]
            set color [color] of parent
            let parent-color [color] of parent
            create-link-from parent [set color parent-color]
          ]
        ]
        set vcount vcount + 1
      ]
    ]
  ]
end


to plot-graphs
  set-current-plot "Graph"
  if show-Graph = "Eligibility Traces"[
    set i 0
    while [i < num_inputs] [
      create-temporary-plot-pen (item i input_labels)
      set-current-plot-pen (item i input_labels)
      set-plot-pen-color (item i input_colors)
      plot item i traces
      set i i + 1
    ]
  ]
  if show-Graph = "Memory Input Reactivation"[
    set i 0
    while [i < num_inputs - 3] [
      create-temporary-plot-pen (item i input_labels)
      set-current-plot-pen (item i input_labels)
      set-plot-pen-color (item i input_colors)
      plot item i imag_senses_left
      plot item i imag_senses_right
      set i i + 1
    ]
  ]
  if show-Graph = "FA Matrix: Strength of X,Y"[
    set-plot-y-range 0 2
    create-temporary-plot-pen (word Sense_X Sense_Y "S")
    set-current-plot-pen (word Sense_X Sense_Y "S")
    set-plot-pen-color black
    plot matrix:get FAMatrix_strengths Sense_X Sense_Y
  ]
  if show-Graph = "FA Matrix: Order of X,Y"[
    set-plot-y-range -20 20
    create-temporary-plot-pen (word Sense_X Sense_Y "O")
    set-current-plot-pen (word Sense_X Sense_Y "O")
    set-plot-pen-color green
    plot matrix:get FAMatrix_timelags Sense_X Sense_Y
  ]
  if show-Graph = "FA Matrix: Reward of X,Y"[
    set-plot-y-range 0 10
    create-temporary-plot-pen (word Sense_X Sense_Y "R")
    set-current-plot-pen (word Sense_X Sense_Y "R")
    set-plot-pen-color red
    plot matrix:get FAMatrix_rewards Sense_X Sense_Y
  ]
  if show-Graph = "Turn-Angle"[
    set-plot-y-range -5 5
    create-temporary-plot-pen "H"
    set-current-plot-pen "H"
    set-plot-pen-color black
    plot HDOut; turn-angle ;HDHomeostat
  ]
end


to plot-senses
    set-current-plot "Sensors"
    clear-plot
    set-plot-background-color black
    set senses ( lput sns-pain sns_odors )
    set senses_left (lput sns-pain-left sns_odors_left)
    set senses_right (lput sns-pain-right sns_odors_right)
    set-plot-x-range 0 2 * (num_senses + 3)
    let x-center (num_senses + 3)
    let bwidth 1
    let bgap 0.05
    set-plot-y-range 0 8
    set i 0
    while [i < num_senses][
      create-temporary-plot-pen (item i sense_names)
      set-current-plot-pen (item i sense_names)
      set-plot-pen-color (item i sense_colors)
      set-plot-pen-interval 0.1
      set-plot-pen-mode 1
      let left_length (item i senses_left)
      let right_length (item i senses_right)
      let left-x x-center - 2 - i
      let right-x x-center + 2 +  i
      foreach (range -0.5 0.5 0.1) [x-shift -> plotxy (left-x + x-shift) left_length]
      foreach (range -0.5 0.5 0.1) [x-shift -> plotxy (right-x + x-shift) right_length]
      set i i + 1
    ]
end


to plot-recalled-senses
    set-current-plot "Recalled Senses"
    clear-plot
    set-plot-background-color black
    set-plot-x-range 0 2 * (num_senses + 3)
    let x-center (num_senses + 3)
    let bwidth 1
    let bgap 0.05
    set-plot-y-range 0 8
    set i 0
    while [i < num_inputs - 1][
      create-temporary-plot-pen (item i input_labels)
      set-current-plot-pen (item i input_labels)
      set-plot-pen-color (item i input_colors)
      set-plot-pen-interval 0.1
      set-plot-pen-mode 1
      let left_length (item i imag_senses_left)
      let right_length (item i imag_senses_right)
      let left-x x-center - 2 - i
      let right-x x-center + 2 +  i
      foreach (range -0.5 0.5 0.1) [x-shift -> plotxy (left-x + x-shift) left_length]
      foreach (range -0.5 0.5 0.1) [x-shift -> plotxy (right-x + x-shift) right_length]
      set i i + 1
    ]
end


to-report set-element [nestedlist i_row j_col new_element]
  let old_row item i_row nestedlist
  let new_row replace-item j_col old_row new_element
  report replace-item i_row nestedlist new_row
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

to-report average-vectors [v1 v2]
  let angle1 item 0 v1
  let l1 item 1 v1
  let angle2 item 0 v2
  let l2 item 1 v2
  let v1x l1 * sin angle1
  let v1y l1 * cos angle1
  let v2x l2 * sin angle2
  let v2y l2 * cos angle2
  let xcomp_avg (v1x + v2x) / 2
  let ycomp_avg (v1y + v2y) / 2
  let l3 sqrt ((xcomp_avg)^ 2 + (ycomp_avg) ^ 2)
  let angle3 0
  if v1x + v2x != 0 and v1y + v2y != 0 [set angle3 atan (xcomp_avg) (ycomp_avg)]
  report (list angle3 l3)
end


to-report subtract-vectors [v1 v2] ; v1 - v2
  let angle1 item 0 v1
  let l1 item 1 v1
  let angle2 item 0 v2
  let l2 item 1 v2
  let v1x l1 * sin angle1
  let v1y l1 * cos angle1
  let v2x l2 * sin angle2
  let v2y l2 * cos angle2
  let l3 sqrt ((v1x - v2x)^ 2 + (v1y - v2y) ^ 2)
  let angle3 0
  if v1x - v2x != 0 and v1y - v2y != 0 [set angle3 atan (v1x - v2x) (v1y - v2y)]
  report (list angle3 l3)
end

to-report sign2 [val]
  ifelse val <= 0 [report 0][report 1]
end

to-report sign3 [val]
  ifelse val = 0 [report 0][
  report val / abs val
  ]
end

to-report sign-thresh [val thresh m1 m2]
  ifelse val <= thresh [report m1][report m2]
end

;; count the number of occurrences of an item in a list
to-report occurrences [x the-list]
  report reduce
    [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 the-list)
end


to-report round-list [v p] ;Recursive function! to round all elements in a list (even nested)
  ifelse is-list? v [report (map [[vitem] -> (round-list vitem p)] v)] [report precision v p]
end


to-report factorial [n]; unused
  ifelse n <= 1 [report 1][report n * factorial (n - 1)]
end
;-----------------------------------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------------------------------

;;==========================================================================================================================================
;;                                         U S E R     A P P L I C A T I O N     F U N C T I O N S
;;==========================================================================================================================================

;can drag items
to drag
  if mouse-down? [
    let nearest-items turtles with [(breed = cslugs or breed = pebbles or breed = wallpts or breed = prey) and distancexy mouse-xcor mouse-ycor < 5]
    if any? nearest-items[
      ask min-one-of nearest-items [distancexy mouse-xcor ycor] [
        setxy mouse-xcor mouse-ycor
        if breed = cslugs [set forward-movement 0 update-arms]
      ]
    ]
  ]
end

;=======================================================================================================
;             Functions for Presentation Mode
;=======================================================================================================
;
;                  Presentation Mode:
;                  ---------------------------
;                      Cslug is immobilized, except for turning, and can be fed or
;                      presented with prey or drug, to monitor approach-avoidance turns
;                      To start, set Presentation-Mode to ON, and click on the Present button.

;                      Note that Satiation can be fixed via the Fix-var1 switch and fix-satiation slider,
;                      and Reward Experience can be fixed via the Fix-var2 switch and fix-RewardExperience slider.
;-------------------------------------------------------------------------------------------------------

  ;---------------------------------------------------------------------------------------------------
  ;                     Feeding Cslug with Prey or Drug (function)
  ;---------------------------------------------------------------------------------------------------
  ;                        INSTRUCTIONS: Choose prey or drug type from the Feeding-Choice
  ;                        drop-down menu, then click on the Feed button. This will spawn the
  ;                        selected item right at the mouth of Cslug, effectively feeding it the item.
  ;---------------------------------------------------------------------------------------------------

to Feed-Function [Choice]
  clear-patches
  let xc 0
  let yc Present-y-coord + 6
  set immobilize true
  ask prey [die]
  ask Cslugs [set heading 0 setxy 0 Present-y-coord]
  create-prey 1 [set prey-type Choice setxy xc yc]
end

  ;---------------------------------------------------------------------------------------------------
  ;                     Presentation of Prey or Drug (function)
  ;---------------------------------------------------------------------------------------------------
  ;                        INSTRUCTIONS: Choose prey or drug type from the Presentation-Choice
  ;                        drop-down menu, then click on the Present button. This will spawn the
  ;                        selected item on the left side of Cslug, which may cause it to turn away
  ;                        or towards the item.
  ;---------------------------------------------------------------------------------------------------
to Present
  if Presentation-Mode = true[
    ifelse Presentation-Choice = "Temporal Sequence 1"[
      set pticks 0
      set pstep 0
      set Presenting "starting TS1..."
    ][
      ifelse Presentation-Choice = "Temporal Sequence 2"[
        set pticks 0
        set pstep 0
        set Presenting "starting TS2..."
      ][
        Present-Function Presentation-Choice
        set pstep -1
        set Presenting Presentation-Choice
      ]
    ]
  ]
end

to Present-Function [Choice]
  set Presentation-Mode true
  set Immobilize true
  ;ask Cslugs[set pain 0]
  clear-patches
  let xc 9
  let yc 13
  set immobilize true
  ask prey [die]
  ask Cslugs [
    set heading 0
    setxy 0 Present-y-coord
    set imag_senses_left n-values ((num-odor-types - 1) + 1) [0]  ;reset image senses so there is no residual turning for next presentation
    set imag_senses_right n-values ((num-odor-types - 1) + 1) [0]
  ]

  if Choice = "drug vs hermi"[
    create-prey 1 [set prey-type "drug" set fixed 1 setxy (- xc - 1) yc]
    create-prey 1 [set prey-type "hermi" set fixed 1 setxy (xc + 1) yc]
  ]
  if Choice = "drug vs flab"[
    create-prey 1 [set prey-type "drug" set fixed 1 setxy (- xc - 1) yc]
    create-prey 1 [set prey-type "flab" set fixed 1 setxy (xc + 1) yc]
  ]
  if Choice = "hermi vs flab"[
    create-prey 1 [set prey-type "hermi" set fixed 1 setxy (- xc - 1) yc]
    create-prey 1 [set prey-type "flab" set fixed 1 setxy (xc + 1) yc]
  ]
  if Choice = "None"[]
  if member? Choice ["hermi" "flab" "drug"] [create-prey 1 [set prey-type Choice set fixed 1 setxy (- xc) yc]]
end

to present-Temporal-Sequences
  let start_time 10
  let presentation_time 80
  let presentation_time2 100
  let feed_time 10
  let break_time 110 ; TS1 : 130, TS2 : 110
  let endbreak_time 50

if member? "TS1" Presenting[
  if pstep = 0 and pticks = start_time [set pticks 0 set pstep pstep + 1 Present-Function "flab" set Presenting "(TS1) flab, Next: hermi"]
  if pstep = 1 and pticks = presentation_time [set pticks 0 set pstep pstep + 1 Present-Function "hermi" set Presenting "(TS1) hermi, Next: drug"]
  if pstep = 2 and pticks = presentation_time [set pticks 0 set pstep pstep + 1 Present-Function "drug" set Presenting "(TS1) drug, Next: feed drug (reward)"]
  if pstep = 3 and pticks = presentation_time [set pticks 0 set pstep pstep + 1 Feed-Function "drug" set Presenting "(TS1) drug fed (reward), Next: break"]
  if pstep = 4 and pticks = feed_time [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS1) break, Next: flab"]

  if pstep = 5 and pticks = break_time [set pticks 0 set pstep pstep + 1 Present-Function "flab" set Presenting "(TS1) flab, Next: break"]
  if pstep = 6 and pticks = presentation_time2 [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS1) break, Next: hermi"]

  if pstep = 7 and pticks = break_time [set pticks 0 set pstep pstep + 1 Present-Function "hermi" set Presenting "(TS1) hermi, Next: break"]
  if pstep = 8 and pticks = presentation_time2 [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS1) break, Next: drug"]

  if pstep = 9 and pticks = break_time [set pticks 0 set pstep pstep + 1 Present-Function "drug" set Presenting "(TS1) drug, Next: break"]
  if pstep = 10 and pticks = presentation_time2 [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS1) break, Next: end"]
  if pstep = 11 and pticks = endbreak_time [set pticks 0 set pstep -1 Present-Function "None" set Presenting ""]
]

if member? "TS2" Presenting[
  if pstep = 0 and pticks = start_time [set pticks 0 set pstep pstep + 1 Present-Function "drug" set Presenting "(TS2) drug, Next: feed drug (reward)"  print pticks]
  if pstep = 1 and pticks = presentation_time [set pticks 0 set pstep pstep + 1 Feed-Function "drug" set Presenting "(TS2) drug fed (reward), Next: break"   print pticks]
  if pstep = 2 and pticks = feed_time [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS2) break, Next: flab"]

  if pstep = 3 and pticks = break_time [set pticks 0 set pstep pstep + 1 Present-Function "flab" set Presenting "(TS2) flab, Next: drug"]
  if pstep = 4 and pticks = presentation_time [set pticks 0 set pstep pstep + 1 Present-Function "drug" set Presenting "(TS2) drug, Next: break"]
  if pstep = 5 and pticks = presentation_time [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS2) break, Next: hermi"]

  if pstep = 6 and pticks = break_time [set pticks 0 set pstep pstep + 1 Present-Function "hermi" set Presenting "(TS2) hermi, Next: flab"]
  if pstep = 7 and pticks = presentation_time [set pticks 0 set pstep pstep + 1 Present-Function "flab" set Presenting "(TS2) flab, Next: break"]
  if pstep = 8 and pticks = presentation_time [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS2) break, Next: hermi"]

  if pstep = 9 and pticks = break_time [set pticks 0 set pstep pstep + 1 Present-Function "hermi" set Presenting "(TS2) hermi, Next: break"]
  if pstep = 10 and pticks = presentation_time2 [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS2) break, Next: flab"]

  if pstep = 11 and pticks = break_time [set pticks 0 set pstep pstep + 1 Present-Function "flab" set Presenting "(TS2) flab, Next: break"]
  if pstep = 12 and pticks = presentation_time2 [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS2) break, Next: drug"]

  if pstep = 13 and pticks = break_time [set pticks 0 set pstep pstep + 1 Present-Function "drug" set Presenting "(TS2) drug, Next: break"]
  if pstep = 14 and pticks = presentation_time2 [set pticks 0 set pstep pstep + 1 Present-Function "None" set Presenting "(TS2) break, Next: end"]
  if pstep = 15 and pticks = endbreak_time [set pticks 0 set pstep -1 Present-Function "None" set Presenting ""]
]
end


;=======================================================================================================
;             Pain Application (Functions)
;=======================================================================================================
;                  To apply a painful stimulus to Cslug, set the pain value via the apply_pain slider,
;                  and click on the Poke-Left or Poke-Right button.
;-------------------------------------------------------------------------------------------------------
to Poke-Left
  ask Cslugs[
    set sns-pain-left sns-pain-left + Apply_Pain
  ]
end

to Poke-Right
  ask Cslugs[
    ;set pain 1
    set sns-pain-right sns-pain-right + apply_pain
  ]
end


;=============================================================================================================
;             Addiction Cycle
;=============================================================================================================
;                  The Addiction Cycle mode will start off a series of events that causes the forager to go
;                  through the phases of addiction over the course of 60000 ticks.
;
;                  Before enabling the Addiction Cycle Mode, make sure Presentation_Mode and Immobilize are both OFF.
;                  The easiest way to to make sure everything is ready and set up for the Addiction Cycleis is to click
;                  on the Reset to Default Settings button at the bottom center of the interface. The populations of hermi
;                  and flab can be set beforehand to the desired amounts. These will not change throughout the addiction cycle.
;                  If desired, variables can also be fixed beforehand, but it is recommended to observe the Addiction Cycle without the fixation of any variables.
;
;                  Once everything is ready and set as desired, set the Addiction_Cycle switch to ON.
;                  It is recommended to not alter any controls during this process in order to observe a fully-functioning Addiction Cycle, but above all, please refrain
;                  from altering the drug population sliders during this process. Take note of the graph of the total prey and drug consumed and how it changes throughout the phases
;                  of the Addiction Cycle.The Addiction Cycle takes a total of 60000 ticks to complete.
;
;                  The forager will start out in an environment with no drugs and only prey in the Drug-Free phase.
;                  In the Drug Introduced phase, 5 drugs are spawned, allowing the forager to start
;                  drug consumption. Note that drug consumption typically occurs when the forager is
;                  very hungry, or by accident, if it was trying to consume another prey nearby.
;                  The next phase is the Drug Removed phase, where all drugs are removed. During this phase
;                  The forager is likely to undergo withdrawal and recovery from withdrawal.
;                  Following this is the Drug Without Reward phase, where 5 drug items are spawned again, emitting the same drug odor,
;                  but providing no reward instead of a high positive reward.
;                  In the beginning of this phase the forager is likely to demonstrate cravings by resuming drug consumption
;                  to some extent, due to the strong learned association, but over time as associative strength goes down, its
;                  drug consumption rate should be lower than before in the phase where the drug was first introduced.
;-------------------------------------------------------------------------------------------------------------
to switch_on

  let drugs prey with [prey-type = "drug"]
  if Addiction_Cycle[
    ifelse Addiction_Cycle_Phase = "Drug-Free" [
      create-prey 6 [set prey-type "drug" setxy random-xcor random-ycor ]
      set Addiction_Cycle_Phase "Drug Introduced"
    ][

      ifelse Addiction_Cycle_Phase = "Drug Introduced" [
        if any? drugs[ask drugs [die]]
        set Addiction_Cycle_Phase "Drug Removed"
      ][

        if Addiction_Cycle_Phase = "Drug Removed" [
          if any? drugs[ask drugs [die]]
          create-prey 6 [set prey-type "drug" setxy random-xcor random-ycor]
          ask Cslugs [ set drug_reward 0]
          set Addiction_Cycle_Phase "Drug Without Reward"
        ]
      ]
    ]
  ]
end


;=============================================================================================================
;             Q-Learning Functions
;=============================================================================================================

to-report discretize-senses [sL sR]
  let smin min (list sL sR)
  let sL_mod sign2 (precision (sL - smin) 1)
  let sR_mod sign2 (precision (sR - smin) 1)
  let sL_d (sign2 sL) + sL_mod
  let sR_d (sign2 sR) + sR_mod
  report (list sL_d sR_d)
end

to goRight
  if max senses = 0 [
    set forward-movement 1
    set heading heading + 10
    fd forward-movement
  ]
end

to goLeft
  if max senses = 0 [
    set forward-movement 1
    set heading heading - 10
    fd forward-movement
  ]
end

to Approach
  set App_State_Switch -1
end

to Avoid
  set App_State_Switch 1
end

to resetPosition
  pen-up
  set slitherometer 0 set vsum [0 0]
  let idnum position EXPERIMENT_MODE exp-mode-list
  let position-values item idnum exp-mode-agent-pos-matrix
  set heading item 0 position-values
  set xcor item 1 position-values
  set ycor item 2 position-values
  pen-down
end

to resetEpisode
  set q-learning_trial_count q-learning_trial_count + 1
  resetPosition
  set-current-plot "Ave Reward Per Episode"
  set-current-plot-pen (word who)
  plot mean reward-list_Q
  set reward-list_Q []
end

to-report bla
  report "c"
end

to-report rewardFunc
  set reward-list_Q lput [reward_Q] of patch-here reward-list_Q
  report [reward_Q] of patch-here
end

to-report isEndState
  if [endstate?_Q] of patch-here = true[
    report true
  ]
  report false
end

to set-patch-rewards
  ask patches [set reward_Q -2]
  ask patches [
    if (abs pxcor > max-pxcor - 30) or (abs pycor > max-pycor - 30) [
      let x-walldist max-pxcor - abs pxcor
      let y-walldist max-pycor - abs pycor
      let min-walldist min (list x-walldist y-walldist)
      set reward_Q (int -300 / (min-walldist + 1))
    ]
  ]
  ask prey [
    ask patches in-radius 20 [set reward_Q 36 - 2 * (int distance myself)]
    if prey-type = "drug" [
      ;ask patches in-radius 6 [set reward_Q 100 set endstate?_Q true]
      ask patches in-radius 4 [set reward_Q 200 set endstate?_Q true]
    ]
  ]
  ask patches [if (abs pxcor > max-pxcor - 6) or (abs pycor > max-pycor - 6) [set reward_Q -100 set endstate?_Q true]]

end

to update-state-inputs
  set discretized-sns-odors []
  let indices range(length sns_odors_left)
  (foreach indices sns_odors_left sns_odors_right [[n sol sor] ->
    set discretized-sns-odors (sentence discretized-sns-odors (discretize-senses sol sor))
    ])
  set slitherometer_Q precision slitherometer 0
  set heading_Q precision heading 0
  set vsum-dir_Q precision (item 0 vsum) 0
  set vsum-dist_Q precision (item 1 vsum) 0
  set-variables q-learning-sns-list discretized-sns-odors
end

to clear-trails-save-view
  export-view (word "QRUN_trial" q-learning_trial_count "_tick" ticks ".png")
  clear-drawing
end

to export-view-at-ticks [tick-list]
;  let EMchar item 0 EXPERIMENT_MODE
;  let LMchar item 0 LEARNING_MODE
;  if  ticks mod 1000 = 0 [export-view (word "ASIMOV-FAM_E" EMchar "_L" LMchar "_tick" ticks ".png")]
  if member? ticks (parse-string tick-list " " true)[
    print (word "screenshot at " ticks)
    let EMchar item 0 EXPERIMENT_MODE
    let LMchar item 0 LEARNING_MODE
    export-view (word "ASIMOV-FAM_E" EMchar "_L" LMchar "_tick" ticks ".png")
    ]
end
;=======================================================================================================
;             Reset to Default Settings (Function)
;=======================================================================================================
;                All adjustable sliders and controls on the interface are reset to their default setting.
;-------------------------------------------------------------------------------------------------------
to reset
  set Presentation-Mode false
  set Experiment_Mode "3 Source Spatial Mapping"
  set Learning_Mode "Feature Association Matrix (FAM)"
  set immobilize false
  set Presentation-Choice "Temporal Sequence 1"
  set Feeding-Choice "drug"
  set fix-RewardExp 0
  set fix-SomaticMap 0
  set Fix-var1: true
  set Fix-var2: false
  set Fix-var3: false
  set Addiction_Cycle false
  set hermi-populate 6
  set flab-populate 6
  set drug-populate 0
  set apply_pain 10
  set force-turn 0
  set QL-minimal-states? false
  set show-Q-rewards false
  set Save-Data false
  set fix-matrix false
 set show-memorylabels false
end

;=======================================================================================================
;             Save and Load Functions for Environment
;=======================================================================================================
;
;-------------------------------------------------------------------------------------------------------
to save-environment
  carefully [ file-delete "ENVConfig.csv" ] [ ]
  file-open "ENVConfig.csv"
  ask wallpts [
    file-print csv:to-row (list xcor ycor)
  ]
  file-close
end

to load-environment
  set data csv:from-file "ENVConfig.csv"
  ask wallpts [
    let xcoord item 0 (item (wall-id - 1) data)
    let ycoord item 1 (item (wall-id - 1) data)
    setxy xcoord ycoord
  ]
end


to-report add-outer-quotes [str]
  report (word "\"" str "\"")
end

to-report parse-string [str delimiter convert-to-number]
  let remove-brackets ["[" "]" "(" ")" "{" "}"]
  let temp-string str
  foreach remove-brackets [bracket -> set temp-string remove bracket temp-string]
  let parsed-list []
  while [position delimiter temp-string != false] [
    let next-parsed-element  (substring temp-string 0 position delimiter temp-string)
    if convert-to-number = true [set next-parsed-element read-from-string next-parsed-element]
    if convert-to-number = "quote" [set next-parsed-element add-outer-quotes next-parsed-element]
    set parsed-list lput (next-parsed-element) parsed-list
    repeat (position delimiter temp-string + 1) [
      set temp-string (but-first temp-string)
    ]
  ]
  if convert-to-number = true [set temp-string read-from-string temp-string]
  if convert-to-number = "quote" [set temp-string add-outer-quotes temp-string]
  set parsed-list lput (temp-string) parsed-list
  report parsed-list
end

to-report format-string-for-matrix [str] ;unused
  let temp-string str
  let matrix-list []
  ifelse member? "{" str[
    set temp-string remove "matrix:" temp-string
    set temp-string remove "{" temp-string
    set temp-string remove "}" temp-string
    set matrix-list temp-string
  ][
    set temp-string remove "matrix:    " (substring str 0 (length str - 3))
    let first-dim parse-string temp-string "  " false
    let row-count 0
    foreach first-dim [ row-string ->
      if first row-string = " " [set row-string but-first row-string]
      if last row-string = " " [set row-string but-last row-string]
      set matrix-list insert-item row-count matrix-list (parse-string row-string " " true)
      set row-count row-count + 1
    ]
  ]
  report matrix-list
end

to set-variables [variable-list variable-values]
  (foreach variable-list variable-values [[vname vval] ->
    if is-string? vval [
      ifelse member? "matrix:" vval[
        set vval remove "matrix:" vval
        set vval remove "{" vval
        set vval remove "}" vval
        set vval word "matrix:from-row-list " vval
      ][
        carefully [set vval read-from-string vval][
          ifelse member? "[" vval and member? "]" vval and member? "]" vval [set vval parse-string vval " " "quote"][set vval add-outer-quotes vval]
        ]
      ]
    ]
    run (word "set " vname " " vval)
  ])
end

to-report full-var-list
  report (word "xcor ycor heading Somatic_Map App_State App_State_Switch ExpReward_pos ExpReward_neg iSum Incentive Nutrition Satiation speed forward-movement turn-angle "
        "sns_betaine sns_betaine_left sns_betaine_right sns-pain-left sns-pain-right sns-pain-caud sns-pain spontaneous-pain pain pain-switch "
        "odors_left odors_right sns_odors_left sns_odors_right sns_odors Somatic_Map_Factors Somatic_Map_Sigmoids "
        "num_senses sense_names senses imag_senses imag_senses_accumulators senses_left imag_senses_left senses_right imag_senses_right sense_colors "
        "hermcount flabcount fauxflabcount drugcount drug_reward "
        "R R_hermi R_flab R_drug RewardExperience deg_sensitization IN M M0 W1 W2 W3 dW3 W4 W5 "
        "inputs inputs_left inputs_right num_inputs traces memory_traces input_labels input_colors "
        "i j FAMatrix_dim init_list FAMatrix_diff-A FAMatrix_cross-A FAMatrix_strengths FAMatrix_timelags FAMatrix_rewards FAMatrix_vdir FAMatrix_vdist FAMatrix_vec FAMatrix_vtemp FAMatrix_vseq reward_pos reward_neg "
        "Incentives Imag_Incentives Realsense_Rewards Direct_Rewards DirectReward_i Imag_Rewards ImagReward_i "
        "slitherometer head-direction vsum stepsize trace-track vseq_temp vseq_count vseq_sum detour-vector correction-vector HDOut HDWeight HD0 HDtau "
        "HLB HLS HLD sensor_angle lsns_vec rsns_vec left_dist right_dist dist "
        "turn-angle-accumulation trace-changes")
end

to-report get-var-values [parsed-var-list]
  set var-val-list []
  foreach parsed-var-list [var ->
    run (word "set var-val-list lput " var " var-val-list")
  ]
  report var-val-list
end

to save-agent-vars [var-list]
  ;carefully [ file-delete "AgentVars.csv" ] [ ]
  ;file-open "AgentVars.csv"
  let file user-new-file
  carefully [ file-delete file ] [ ] ;over-write if saving over existing file
  if file != false [
    file-open file
    let parsed-var-list parse-string var-list " " false
    ask cslug 0 [
      file-print csv:to-row parsed-var-list
      file-print csv:to-row get-var-values parsed-var-list
    ]
    file-close
  ]
end

to load-agent-vars
  ;set data csv:from-file "AgentVars.csv"
  let file user-file
  if file != false [
    set data csv:from-file file
    ask cslug 0 [
      pen-up
      let var-name-list (item 0 data)
      set-variables var-name-list (item 1 data)
      update-arms
      pen-down
    ]
    file-close
  ]
end


to write-to-file
  let input_names ["Odor 2 Left" "Odor 2 Right" "Odor 1 Left" "Odor 1 Right" "Odor 3 Left" "Odor 3 Right" "Pl" "Pr" "Reward" "R-"]
  let trace_names ["E2 L" "E2 R" "E1 L" "E1 R" "E3 L" "E3 R" "Pl" "Pr" "R+" "R-"]
  let file file-name
  carefully [ file-delete file ] [ ] ;over-write if saving over existing file
  if file != false [
    file-open file
    ask cslug 0 [
      if ticks = 0 [file-print csv:to-row (sentence 0 input_names trace_names "Heading" "Turn Angle" "Incentive")]
      file-print csv:to-row (sentence ticks inputs traces heading turn-angle incentive)
    ]
  ]
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
207
10
730
534
-1
-1
3.37
1
12
1
1
1
0
1
1
1
-76
76
-76
76
1
1
1
ticks
60.0

BUTTON
7
100
74
133
SETUP
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
138
100
201
133
GO
if Pause-At-Tick: = 0 or ticks < Pause-At-Tick: [ Go ]
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
73
100
139
133
STEP
Go
NIL
1
T
OBSERVER
NIL
F
NIL
NIL
1

MONITOR
729
53
786
98
Satiation
[satiation] of Cslug 0
2
1
11

MONITOR
1632
72
1937
117
Real-Sense Rewards
[round-list Realsense_Rewards 2] of Cslug 0
2
1
11

MONITOR
924
10
1021
55
Somatic Map
[Somatic_Map] of Cslug 0
2
1
11

MONITOR
824
10
925
55
App. State Switch
[App_State_Switch] of Cslug 0
2
1
11

SLIDER
1699
456
1871
489
flab-populate
flab-populate
0
15
5.0
1
1
NIL
HORIZONTAL

SLIDER
1699
423
1871
456
hermi-populate
hermi-populate
0
15
3.0
1
1
NIL
HORIZONTAL

SLIDER
1699
488
1871
521
drug-populate
drug-populate
0
15
2.0
1
1
NIL
HORIZONTAL

PLOT
1149
418
1461
538
Graph
NIL
NIL
0.0
15.0
0.0
1.0
true
false
"" "set-plot-x-range plot-timer ticks"
PENS
"pen-1" 1.0 0 -13345367 true "" ";plot [RewardExperience] of Cslug 0;plot [ExpReward + ExpReward_neg] of Cslug 0"
"pen-2" 1.0 0 -5298144 true "" ";plot [M - M0] of Cslug 0"

PLOT
730
103
1130
223
Incentive,Satiation, and Reward Experience
NIL
NIL
0.0
10.0
0.0
10.5
true
true
"" ""
PENS
"Incen" 1.0 0 -16777216 true "" "if any? Cslugs [plot [Incentive] of Cslug 0]"
"RExp" 1.0 0 -13345367 true "" "if any? Cslugs [plot [RewardExperience] of Cslug 0]"
"Sat" 1.0 0 -5825686 true "" "if any? Cslugs [plot [Satiation] of Cslug 0]"

MONITOR
1001
53
1078
98
Reward Input
[R] of Cslug 0
2
1
11

MONITOR
1020
10
1138
55
Reward Experience
[RewardExperience] of Cslug 0
3
1
11

SWITCH
9
545
204
578
Immobilize
Immobilize
1
1
-1000

MONITOR
729
10
824
55
Appetitve State
[App_State] of Cslug 0
4
1
11

SWITCH
8
366
204
399
Presentation-Mode
Presentation-Mode
1
1
-1000

CHOOSER
66
400
204
445
Presentation-Choice
Presentation-Choice
"Temporal Sequence 1" "Temporal Sequence 2" "none" "hermi" "flab" "drug" "drug vs hermi" "drug vs flab" "hermi vs flab"
0

BUTTON
8
399
64
445
NIL
Present
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
97
252
207
285
fix-Satiation
fix-Satiation
0.01
1
0.1
0.01
1
NIL
HORIZONTAL

CHOOSER
66
454
204
499
Feeding-Choice
Feeding-Choice
"hermi" "flab" "drug"
2

BUTTON
9
454
64
499
Feed
Feed-Function Feeding-Choice
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
2
252
97
285
Fix-var1:
Fix-var1:
1
1
-1000

SLIDER
97
284
207
317
fix-RewardExp
fix-RewardExp
-20
20
0.0
1
1
NIL
HORIZONTAL

SWITCH
2
284
97
317
Fix-var2:
Fix-var2:
1
1
-1000

BUTTON
12
170
101
203
NIL
Poke-Left
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
102
170
190
203
NIL
Poke-Right
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
12
203
190
236
Apply_Pain
Apply_Pain
0
30
10.0
1
1
NIL
HORIZONTAL

MONITOR
785
53
841
98
Pain
[pain] of Cslug 0
4
1
11

MONITOR
840
53
905
98
Pain Switch
[pain-switch] of Cslug 0
3
1
11

TEXTBOX
1701
406
1874
424
Prey and Drug Population Controls:\n
11
23.0
1

TEXTBOX
41
155
181
173
Pain Application Controls:
11
23.0
1

TEXTBOX
51
238
171
256
Fixation of Variables:
11
23.0
1

TEXTBOX
35
352
198
370
Presentation Mode Controls:
11
23.0
1

SWITCH
1
316
97
349
Fix-var3:
Fix-var3:
1
1
-1000

SLIDER
97
316
207
349
fix-SomaticMap
fix-SomaticMap
-10
10
0.0
1
1
NIL
HORIZONTAL

SWITCH
1566
424
1689
457
Addiction_Cycle
Addiction_Cycle
1
1
-1000

MONITOR
1566
457
1689
502
NIL
Addiction_Cycle_Phase
3
1
11

PLOT
730
221
1131
341
Total Prey and Drug Eaten
NIL
NIL
0.0
10.0
0.0
10.5
true
true
"" ""
PENS
"Drug" 1.0 0 -4079321 true "" "if any? Cslugs [plot [drugcount] of Cslug 0]"
"Hermi" 1.0 0 -11221820 true "" "if any? Cslugs [plot [hermcount] of Cslug 0]"
"Flab" 1.0 0 -4757638 true "" "if any? Cslugs [plot [flabcount] of Cslug 0]"

TEXTBOX
1571
407
1692
425
Addiction Cycle Controls:
11
23.0
1

BUTTON
368
597
562
630
RESET TO DEFAULT SETTINGS
Reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1
441
215
459
------------------------------------------
13
122.0
1

PLOT
1337
55
1497
325
Legend
NIL
NIL
0.0
1.0
0.0
5.0
true
true
"" ""
PENS

PLOT
1151
54
1461
325
Feature Association Matrix
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
952
53
1002
98
R+
[reward_pos] of Cslug 0
2
1
11

MONITOR
904
53
954
98
R-
[reward_neg] of Cslug 0
2
1
11

SWITCH
1400
22
1497
55
Fix-Matrix
Fix-Matrix
1
1
-1000

PLOT
960
357
1120
581
Senses-Legend
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
730
357
902
581
Sensors
NIL
NIL
0.0
10.0
0.0
10.0
false
false
"" ""
PENS

TEXTBOX
773
564
895
587
L e f t   |   R i g h t
12
0.0
1

SWITCH
1573
508
1689
541
Clustering
Clustering
1
1
-1000

SLIDER
1573
540
1689
573
Cluster-Radius
Cluster-Radius
0
50
20.0
5
1
NIL
HORIZONTAL

SLIDER
1573
571
1689
604
Cluster-Distance
Cluster-Distance
0
50
20.0
5
1
NIL
HORIZONTAL

SLIDER
1139
85
1172
295
Sense_Y
Sense_Y
0
10
9.0
1
1
NIL
VERTICAL

SLIDER
1190
308
1436
341
Sense_X
Sense_X
0
10
2.0
1
1
NIL
HORIZONTAL

CHOOSER
1149
390
1461
435
show-Graph
show-Graph
"Eligibility Traces" "Memory Input Reactivation" "FA Matrix: Strength of X,Y" "FA Matrix: Order of X,Y" "FA Matrix: Reward of X,Y" "Turn-Angle"
0

MONITOR
564
534
639
579
Slitherometer
[slitherometer] of Cslug 0
4
1
11

MONITOR
564
579
640
624
Heading
[heading] of Cslug 0
0
1
11

MONITOR
640
534
717
579
Vsum
[round-list vsum 0] of Cslug 0
4
1
11

MONITOR
1342
341
1412
386
Vector
[round-list (list matrix:get FAMatrix_vdir Sense_X Sense_Y matrix:get FAMatrix_vdist Sense_X Sense_Y) 0] of Cslug 0
0
1
11

MONITOR
1246
341
1296
386
Order
[matrix:get FAMatrix_timelags Sense_X Sense_Y] of Cslug 0
2
1
11

MONITOR
1190
341
1246
386
Strength
[matrix:get FAMatrix_strengths Sense_X Sense_Y] of Cslug 0
4
1
11

MONITOR
1292
341
1344
386
Reward
[matrix:get FAMatrix_rewards Sense_X Sense_Y] of Cslug 0
2
1
11

TEXTBOX
1133
358
1235
388
FAM(X,Y):
12
0.0
1

MONITOR
1543
350
1597
395
Cross-A
[matrix:get FAMatrix_cross-A Sense_X Sense_Y] of Cslug 0
4
1
11

MONITOR
1662
345
1740
390
image X left
[item Sense_X imag_senses_left] of Cslug 0
4
1
11

MONITOR
1733
345
1809
390
image X right
[item Sense_X imag_senses_right] of Cslug 0
4
1
11

MONITOR
1806
345
1862
390
image X
[item Sense_X imag_senses] of Cslug 0
4
1
11

MONITOR
1870
345
1927
390
Trace X
[item Sense_X traces] of Cslug 0
4
1
11

MONITOR
1927
345
2004
390
d
[(list (round item 0 dist) (round item 1 dist))] of Cslug 0
4
1
11

MONITOR
1632
116
1937
161
Imagined Rewards
[round-list Imag_Rewards 5] of Cslug 0
2
1
11

MONITOR
1632
206
1937
251
SMap Sigmoids
[round-list Somatic_Map_Sigmoids 2] of Cslug 0
2
1
11

MONITOR
1632
161
1937
206
SMap Exponential Factors
[round-list Somatic_Map_Factors 2] of Cslug 0
2
1
11

MONITOR
1632
250
1846
295
ImagSenses_L
[round-list imag_senses_left 2] of Cslug 0
2
1
11

MONITOR
1845
250
2056
295
ImagSenses_R
[round-list imag_senses_right 2] of Cslug 0
2
1
11

SWITCH
217
533
369
566
Show-MemoryLabels
Show-MemoryLabels
1
1
-1000

SWITCH
370
533
465
566
all-text
all-text
1
1
-1000

BUTTON
218
597
296
630
SAVE-ENV
save-environment
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
296
597
371
630
LOAD-ENV
load-environment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1410
341
1509
386
Vector Sequence
[ round-list (item Sense_Y (item Sense_X FAMatrix_vseq)) 0] of Cslug 0
3
1
11

MONITOR
1913
396
2028
441
vseq_temp
[round-list vseq_temp 0] of cslug 0
17
1
11

CHOOSER
6
10
201
55
EXPERIMENT_MODE
EXPERIMENT_MODE
"Temporal Sequence Learning" "Spatial Sequence Learning" "3 Source Spatial Mapping" "5 Source Spatial Mapping" "Obstacle Avoidance Learning" "Prey Populations"
5

CHOOSER
1151
10
1402
55
show-FAMatrix
show-FAMatrix
"strengths" "time-lags" "rewards" "vectors"
0

PLOT
896
357
1065
581
Recalled Senses
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

TEXTBOX
935
565
1085
583
L e f t   |   R i g h t
12
0.0
1

MONITOR
9
500
204
545
NIL
Presenting
17
1
11

MONITOR
740
664
957
709
ImagSenses
[round-list imag_senses 0] of Cslug 0
17
1
11

MONITOR
1632
28
1896
73
...Somatic-Map Legend...
\"[ H   F   D   O5   O6   O7   O8   O9   O10   P ]\"
17
1
11

MONITOR
1073
53
1138
98
Incentive
[Incentive] of Cslug 0
3
1
11

SWITCH
1130
548
1233
581
Save-Data
Save-Data
1
1
-1000

INPUTBOX
1230
548
1336
608
File-Name
FAMdata.csv
1
0
String

INPUTBOX
1332
548
1507
608
Variables-to-Save
NIL
1
0
String

TEXTBOX
1140
585
1237
603
Text Input Boxes:
11
0.0
1

MONITOR
639
579
715
624
angle-acc
[turn-angle-accumulation] of cslug 0
2
1
11

MONITOR
741
794
957
839
trace-changes
[round-list trace-changes 3] of Cslug 0
17
1
11

MONITOR
741
749
958
794
traces
[round-list traces 3] of Cslug 0
17
1
11

SLIDER
9
578
203
611
Force-Turn
Force-Turn
-10
10
0.0
1
1
NIL
HORIZONTAL

BUTTON
218
566
346
599
SAVE-AGENT-VARS
SAVE-AGENT-VARS full-var-list
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
341
566
466
599
NIL
LOAD-AGENT-VARS
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
466
533
565
598
Pause-At-Tick:
0.0
1
0
Number

MONITOR
740
706
958
751
ImagSensesAccumulators
[round-list imag_senses_accumulators 0] of Cslug 0
17
1
11

MONITOR
1543
304
1597
349
cross
[(abs(item Sense_X traces) * abs(item Sense_Y traces))] of Cslug 0
4
1
11

MONITOR
1598
303
1660
348
diff
[(abs(item Sense_Y traces) - abs(item Sense_X traces))] of Cslug 0
4
1
11

MONITOR
1660
304
1717
349
tsum
[(abs(item Sense_X traces) + abs(item Sense_Y traces))] of Cslug 0
4
1
11

MONITOR
1597
348
1654
393
diff-A
[matrix:get FAMatrix_diff-A Sense_X Sense_Y] of Cslug 0
4
1
11

CHOOSER
6
55
201
100
LEARNING_MODE
LEARNING_MODE
"Feature Association Matrix (FAM)" "Rescorla-Wagner Learning Algorithm" "Q-Learning (Turn Left/Right)" "Q-Learning (Approach/Avoid)"
1

MONITOR
957
663
1141
708
Inputs
[round-list inputs 2] of Cslug 0
17
1
11

MONITOR
957
708
1140
753
Strengths_RW
[round-list strengths_RW 2] of Cslug 0
17
1
11

PLOT
481
675
707
825
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

SWITCH
110
792
252
825
show-Q-rewards
show-Q-rewards
1
1
-1000

PLOT
256
675
478
825
Current Reward
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
"default" 1.0 0 -16777216 true "" "plot [rewardFunc] of Cslug 0"

SWITCH
110
756
253
789
QL-minimal-states?
QL-minimal-states?
1
1
-1000

INPUTBOX
1230
612
1507
672
Screenshot-At-Ticks:
NIL
1
0
String

TEXTBOX
148
712
282
738
Q-Learning:
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

ASIMOV (short for “Algorithm of Selectivity by Incentive and Motivation for Optimized Valuation”) is an agent-based simulation of decision-making processes. It provides a fundamental framework for developing artificial animal behavior and cognition through step-wise modifications, where pre-existing circuitry is plausibly modified for changing function and tested, as in natural evolutionary exaptation. ASIMOV contains a cognitive architecture that is based on the behaviors and neuronal circuitry of the simple predatory sea slug _Pleurobranchaea californica_, and has since been expanded to include more complex behaviors, such as simple aesthetics and addiction dynamics (Gribkova et al., 2020), episodic memory, and spatial navigation.



## HOW IT WORKS

Cognitive mapping builds internal representations of the world and is essential to episodic memory and mental imagery. Here we show how circuitry of basic foraging decision can be straightforwardly expanded for affective valuation and cognitive map construction in the agent-based foraging simulation, ASIMOV, reproducing likely evolutionary pathways.
Behavioral choice in foraging is governed by reward learning and motivation, which interact to assign subjective value to sensory stimuli. These qualities characterize foraging generalists that hunt in variable environments and are precursors to more complex memory systems. ASIMOV’s core decision network is based on neuronal circuitry of cost-benefit decision in the predatory sea-slug _Pleurobranchaea californica_. ASIMOV’s virtual forager affectively integrates sensation, motivation (hunger), and learning to make cost-benefit decisions for approach or avoidance of prey, providing reward and nutrition upon consumption. Olfaction is used for both odorant discrimination and spatial navigation. 

We developed a Feature Association Matrix (FAM) with reward learning and hippocampus-like sequence learning to map and establish relations. It does the basic tasks as most models of hippocampal function, but with much less computational demand. The FAM uses some of the simplest hippocampal-like associative architectures and learning rules for establishing pair-wise associations between sensory inputs and reward inputs. The FAM chains pairwise associations to memorize a sequence and assigns reward values along the chain. It shows how higher-order conditioning mechanisms and sequence memorization gives rise to cognitive mapping, through encoding additional contexts into pair-wise associations. 

Spatial learning for distant landmarks in terms of direction and distance is enabled by a simple path integration system. Further development will include homeostatic plasticity mechanisms that enable more complex spatial mapping, including obstacle avoidance learning by down-sampling complex spatial paths into simplified sequences of navigation vectors. 

Addition of the FAM’s spatial and episodic memory to ASIMOV’s forager shows how the neuronal circuitry of foraging decision may have served as the framework for cognitive mapping in evolution. 



## HOW TO USE IT

The top left hand side of the interface provides the initialization of the simulation, with _different modes available under **Experiment_Mode**, which include demos of temporal and spatial sequence learning, as well as spatial mapping_. While the Feature Association Matrix (FAM) is the primary **Learning_Mode** for this simulation, it can be compared against other learning modes, such as the Rescorla-Wagner and Q-learning algorithms (some Q-learning settings are provided in the bottom middle of the interface). The Setup button initializes the chosen experiment mode simulation, and the Go button runs it. The Reset to Default Settings button restores all variables to their default values. 

In the middle environment panel, the user can manipulate the positions of the forager and prey by clicking and dragging them around the environment. Everything, including the forager, and all landmarks or prey items. The forager can also be immobilized by clicking on the Immobilize switch at the bottom left side. This option still allows for the agent's turning behavior, but not forward movement.

 
On the right hand side, there are several tabs and graphs that monitor the values of certain ASIMOV variables. Progress of learning is shown in the **Feature Association Matrix** interface tab, with different matrices (Strength, Order, Memory Vector) available for observation. The **Senses** graph shows actual sensory activation for left and right sensors of the forager, while the **Recalled Senses** graph shows the reactivation of memories of senses, much like search images, encoded by the FAM. Other tabs and graphs show important quantities used in calculating the decision: the nutritional and satiation states, summed appetitive state (App_State), and the positive and negative rewards and incentives sensed for prey. There is also a tab for the ASIMOV agent's estimate of the odor source (Somatic_Map).

For saving data and simulation states, NetLogo has its own "Export World" feature in NetLogo's topmost menu. In addition to this we have provided functions for saving and loading environments (SAVE-ENV and LOAD-ENV on the left), saving and loading agent variables (SAVE-AGENT-VARS and LOAD-AGENT-VARS below the middle environment panel), and more specific data saving to a csv file for graphing (Save-Data, bottom right) where the user can choose which of the agent's variable to save, by inputing the variable names into the text box "Variables-to-Save".


_There are several types of controls on the left-hand side that the user can manipulate:_


**Pain Application Controls**
Using the Pain Application Controls, the user can also apply a painful poke at the top-left or top-right of the forager via the Poke-Left or Poke-Right buttons. The severity of this painful stimulus can be controlled via the apply_pain slider.

**Fixation of Variables**
To observe the behavior of ASIMOV's forager when certain variables are held constant, the user can use the Fixation of Variables controls. The three variables that can be fixed are Satiation, Reward Experience, and Incentive. To fix the desired variable at a certain value, turn the corresponding Fix-var switch to ON, and set the corresponding slider to the desired value.

**Presentation Mode**
Presentation Mode is a useful tool to control the forager's food and drug intake, as well as to monitor its approach and avoidance behavior with certain prey and drug. Presentation Mode was used in combination with Fixation of variables to construct prey and drug response maps, as well as the pain response map as seen in the ASIMOV paper.
In Presentation Mode, ASIMOV's forager is immobilized, except for turning, and can be fed or
presented with prey or drug, to monitor approach-avoidance turns. To start using presentation mode, set Presentation-Mode to ON, and click on the Present button.


To present prey or drug, choose prey or drug type from the Presentation-Choice drop-down menu, then click on the Present button. This will spawn the selected item on the left side of the forager, which may cause it to turn away or towards the item.

To feed ASIMOV's forager, choose the desired prey or drug type from the Feeding-Choice drop-down menu, then click on the Feed button. This will spawn the selected item right at its mouth, effectively feeding it the item.

_Presentation mode can also be used to present temporal sequences of stimuli in the Temporal Sequence Learning experiment mode._


## References
>Gribkova, E. D., Catanho, M., & Gillette, R. (2020). Simple Aesthetic Sense and Addiction Emerge in Neural Relations of Cost-Benefit Decision in Foraging. Scientific reports, 10(1), 1-11. https://doi.org/10.1038/s41598-020-66465-0
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

armbackup
true
3
Polygon -6459832 true true 191 131 178 103 167 91 147 84 129 90 112 100 104 112 100 126 108 142 120 152 135 161 145 168 150 175 160 190 161 205 157 218 156 221 155 228 155 245 156 254 164 263 154 256 150 241 149 232 149 223 149 216 151 206 147 196 141 190 132 181 126 176 117 171 108 165 93 153 87 143 78 121 80 106 87 87 97 77 106 71 116 66 140 60 162 60 182 66 196 75 203 85 217 116

armbackup2
true
3
Polygon -6459832 true true 187 136 170 103 159 91 141 88 121 90 106 98 96 112 88 125 81 135 68 146 54 152 41 152 27 150 15 143 4 131 -5 114 -11 97 -11 83 -11 71 -9 59 -3 44 7 37 24 36 37 47 21 42 9 44 1 52 -1 70 1 88 6 101 13 113 23 127 31 131 44 134 57 129 65 118 72 106 78 91 89 77 98 71 108 66 132 60 154 60 174 66 188 75 195 85 215 121

armo1l
true
3
Polygon -6459832 true true 142 283 160 247 167 219 163 183 152 151 154 122 177 97 205 86 227 63 232 37 227 24 224 39 217 57 204 71 183 78 165 84 145 98 134 114 130 129 130 149 133 167 138 185 140 200 137 217 128 234 109 256

armo1r
true
3
Polygon -6459832 true true 178 129 171 103 161 88 149 79 134 71 119 70 99 73 81 82 67 91 57 100 46 114 28 128 16 136 -1 140 -20 133 -31 119 -33 107 -33 94 -32 81 -26 69 -20 61 -9 50 2 45 -4 54 -9 58 -13 67 -19 77 -20 90 -18 102 -15 110 -7 118 9 117 21 108 33 98 41 85 52 74 63 61 83 51 104 45 118 42 134 40 154 44 168 52 182 62 193 78 200 91 209 112

armo2l
true
3
Polygon -6459832 true true 231 214 223 192 218 184 200 177 175 186 161 195 135 201 117 193 105 182 92 162 87 143 90 121 100 104 121 84 144 61 148 38 142 25 153 37 158 51 154 66 145 83 130 98 113 116 111 140 118 157 125 167 141 169 154 164 166 158 175 151 188 146 206 145 218 147 232 156 243 165 251 178 255 192

armo2r
true
3
Polygon -6459832 true true 231 214 223 192 218 184 200 177 175 186 161 195 135 201 117 193 105 182 92 162 87 143 90 121 100 104 121 84 144 61 148 38 142 25 153 37 158 51 154 66 145 83 130 98 113 116 111 140 118 157 125 167 141 169 154 164 166 158 175 151 188 146 206 145 218 147 232 156 243 165 251 178 255 192

armo3l
true
3
Polygon -6459832 true true 69 214 77 192 82 184 100 177 125 186 139 195 165 201 183 193 195 182 208 162 213 143 210 121 200 104 179 84 156 61 152 38 158 25 147 37 142 51 146 66 155 83 170 98 187 116 189 140 182 157 175 167 159 169 146 164 134 158 125 151 112 146 94 145 82 147 68 156 57 165 49 178 45 192

armo3r
true
3
Polygon -6459832 true true 195 269 185 243 179 221 176 207 161 194 142 182 126 159 122 138 128 119 136 89 127 56 112 39 133 52 145 72 152 94 151 111 145 126 145 149 159 163 173 174 189 184 201 193 208 204 211 223 225 249

armo4l
true
3
Polygon -6459832 true true 151 256 160 247 167 219 163 183 152 151 154 122 177 97 205 86 227 63 232 37 227 24 224 39 217 57 204 71 183 78 165 84 145 98 134 114 130 129 130 149 133 167 138 185 140 200 137 217 130 229 124 238

armo4r
true
3
Polygon -6459832 true true 149 256 140 247 133 219 137 183 148 151 146 122 123 97 95 86 73 63 68 37 73 24 76 39 83 57 96 71 117 78 135 84 155 98 166 114 170 129 170 149 167 167 162 185 160 200 163 217 170 229 184 247

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

brain
true
0
Polygon -2064490 true false 150 60 165 60 195 75 210 105 210 135 195 165 165 180 150 180
Polygon -2064490 true false 150 60 135 60 105 75 90 105 90 135 105 165 135 180 150 180
Polygon -13791810 false false 150 60 165 60 195 75 210 105 210 135 195 165 165 180 150 180 150 60
Polygon -13791810 false false 150 60 135 60 105 75 90 105 90 135 105 165 135 180 150 180 150 60
Line -13791810 false 195 75 180 90
Line -13791810 false 180 90 165 75
Line -13791810 false 180 90 180 105
Line -13791810 false 165 120 180 135
Line -13791810 false 195 120 180 135
Line -13791810 false 180 135 180 150
Line -13791810 false 180 105 195 120
Line -13791810 false 165 120 165 105
Line -13791810 false 180 150 165 150
Line -13791810 false 180 150 195 165
Line -13791810 false 165 150 150 135
Line -13791810 false 135 75 120 90
Line -13791810 false 120 90 105 90
Line -13791810 false 120 90 135 105
Line -13791810 false 150 120 135 105
Line -13791810 false 135 105 120 135
Line -13791810 false 120 105 105 120
Line -13791810 false 105 120 120 135
Line -13791810 false 135 150 150 135
Line -13791810 false 120 135 120 150
Line -13791810 false 120 150 105 165
Line -13791810 false 120 150 135 165

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

cslug
true
0
Polygon -7500403 true true 135 285 165 285 210 240 240 165 225 105 210 90 195 75 105 75 90 90 75 105 60 165 90 240
Polygon -7500403 true true 150 60 240 60 210 105 90 105 60 60
Polygon -7500403 true true 195 120 255 90 195 90
Polygon -7500403 true true 105 120 45 90 105 90

cslug2
true
2
Polygon -955883 true true 158 100 128 98 119 98 103 99 89 98 81 99 70 112 67 120 63 128 60 137 57 146 55 156 52 169 53 177 57 191 62 208 69 227 79 242 84 252 92 265 97 275 105 282 113 286 122 294 135 301 145 302 153 302 153 278 154 219 158 130
Polygon -955883 true true 139 99 169 97 178 97 194 98 208 97 217 99 227 111 230 119 234 127 237 136 240 145 242 155 245 168 244 176 240 190 235 207 228 226 218 241 213 251 205 264 200 274 192 281 184 285 175 293 162 300 152 301 144 301 144 277 143 218 139 129
Polygon -6459832 true false 198 74 206 81 215 90 223 98 225 104 233 111 236 124 237 135 240 150 239 160 237 176 230 194 224 209 218 226 211 237 205 244 198 251 188 261 177 271 172 276 159 279 150 279 146 237 158 192 147 144 162 92 162 69 180 71
Polygon -6459832 true false 103 75 90 83 83 91 75 99 73 105 65 112 62 125 61 136 58 151 59 161 61 177 68 195 74 210 80 227 87 238 93 245 100 252 110 262 121 272 126 277 138 279 150 280 157 259 139 192 152 155 132 81 137 74 119 71
Polygon -6459832 true false 93 96 83 85 82 76 76 65 72 59 63 45 73 46 77 48 81 45 84 46 88 40 95 43 102 38 106 40 114 37 116 44 118 41 122 38 126 42 129 40 134 40 139 37 146 39 143 41 150 36 156 41 160 40 163 37 167 41 172 39 176 36 180 40 182 44 184 43 189 39 196 41 200 45 204 42 210 40 212 48 218 40 221 44 226 48 228 47 234 46 242 44 240 50 234 56 230 62 226 66 221 77 217 88 208 102 170 87 153 107 145 106 126 90
Polygon -11221820 true false 224 136 152 166 172 78 153 245 216 122 209 95 151 188 229 159 219 199 186 90 187 250 154 223 168 264 179 86 198 243 152 197 212 212 202 179 157 262 200 230
Polygon -11221820 true false 72 137 144 167 124 79 143 246 80 123 85 96 145 189 67 160 77 200 110 91 109 251 142 224 128 265 117 87 98 244 144 198 84 213 94 180 139 263 96 231
Polygon -6459832 true false 200 109 203 97 201 83 212 83 242 76 258 69 261 75 247 83 231 92 219 100 205 105
Polygon -6459832 true false 100 109 97 97 99 83 88 83 58 76 42 69 39 75 53 83 69 92 81 100 95 105
Polygon -11221820 true false 149 57 218 74 206 46 200 91 211 62 230 57 159 46 157 93 152 48 176 76 213 47 170 102 223 49 187 76 186 42 156 103 175 43 212 79 150 71 193 100 198 45 167 54 195 98
Polygon -11221820 true false 155 57 86 74 98 46 104 91 93 62 74 57 145 46 147 93 152 48 128 76 91 47 134 102 81 49 117 76 118 42 148 103 129 43 92 79 154 71 111 100 106 45 137 54 109 98
Polygon -11221820 true false 251 81 260 76 258 68 250 74 248 77
Polygon -11221820 true false 49 81 40 76 42 68 50 74 52 77

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

monster
false
0
Polygon -7500403 true true 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -16777216 true false 165 60 60
Circle -16777216 true false 75 60 60
Polygon -7500403 true true 225 150 285 195 285 285 255 300 255 210 180 165
Polygon -7500403 true true 75 150 15 195 15 285 45 300 45 210 120 165
Polygon -7500403 true true 210 210 225 285 195 285 165 165
Polygon -7500403 true true 90 210 75 285 105 285 135 165
Rectangle -7500403 true true 135 165 165 270

octo
true
0
Polygon -7500403 true true 75 165 90 105 210 105 225 165 255 180 255 255 180 300 120 300 45 255 45 180
Polygon -7500403 true true 225 150 285 105 300 30 285 15 270 90 180 135
Polygon -7500403 true true 90 120 45 90 45 30 60 0 60 75 135 120
Polygon -7500403 true true 210 120 255 90 255 30 240 0 240 75 165 120
Polygon -7500403 true true 75 150 15 105 0 30 15 15 30 90 120 135
Circle -11221820 true false 75 180 60
Rectangle -16777216 true false 90 210 120 225
Circle -11221820 true false 165 180 60
Rectangle -16777216 true false 180 210 210 225
Polygon -7500403 true true 90 120 75 75 75 15 90 0 90 60 120 120
Polygon -7500403 true true 120 120 105 75 105 15 120 0 120 60 150 120
Polygon -7500403 true true 210 120 225 75 225 15 210 0 210 60 180 120
Polygon -7500403 true true 180 120 195 75 195 15 180 0 180 60 150 120

octoarm set
true
2
Polygon -8630108 true false 176 34 163 62 152 74 132 81 114 75 97 65 89 53 85 39 93 23 105 13 120 4 130 -3 135 -10 145 -25 146 -40 142 -53 141 -56 140 -63 140 -80 141 -89 149 -98 139 -91 135 -76 134 -67 134 -58 134 -51 136 -41 132 -31 126 -25 117 -16 111 -11 102 -6 93 0 78 12 72 22 63 44 65 59 72 78 82 88 91 94 101 99 125 105 147 105 167 99 181 90 188 80 202 49
Polygon -6459832 true false 176 34 182 55 183 63 183 67 176 79 193 92 208 98 253 97 253 43
Polygon -955883 true true 186 41 178 63 173 71 155 78 130 69 116 60 90 54 72 62 60 73 47 93 42 112 45 134 55 151 76 171 99 194 103 217 97 230 108 218 113 204 109 189 100 172 85 157 68 139 66 115 73 98 80 88 96 86 109 91 121 97 130 104 143 109 161 110 173 108 187 99 198 90 206 77 210 63
Polygon -14835848 true false 190 37 185 57 179 79 176 93 161 106 142 118 126 141 122 162 128 181 136 211 127 244 112 261 133 248 145 228 152 206 151 189 145 174 145 151 159 137 173 126 189 116 201 107 208 96 211 77 218 58
Polygon -13345367 true false 224 44 215 53 208 81 212 117 223 149 221 178 198 203 170 214 148 237 143 263 148 276 151 261 158 243 171 229 192 222 210 216 230 202 241 186 245 171 245 151 242 133 237 115 235 100 238 83 245 71 251 62

octobackup
true
3
Polygon -6459832 true true 94 139 81 147 72 152 66 160 61 168 56 176 52 188 50 200 49 215 50 225 52 241 56 260 62 277 68 290 76 302 83 311 91 320 100 329 108 335 117 341 128 345 151 345 153 319 152 260 151 220 149 143 128 138 110 135
Polygon -6459832 true true 202 138 215 146 224 151 230 159 235 167 240 175 244 187 246 199 247 214 246 224 244 240 240 259 234 276 228 289 220 301 213 310 205 319 196 328 188 334 179 340 168 344 145 344 143 318 144 259 145 219 147 142 168 137 186 134
Polygon -8630108 true false 62 207 134 234 114 149 133 316 70 193 75 166 135 259 57 230 67 270 100 161 99 321 132 294 118 335 107 157 88 314 134 268 74 283 84 250 129 333 86 301
Polygon -8630108 true false 234 205 162 235 182 147 163 314 226 191 219 164 161 257 239 228 229 268 196 159 197 319 164 292 178 333 189 155 208 312 162 266 222 281 212 248 167 331 210 299
Polygon -6459832 true true 225 152 219 131 218 123 218 119 225 107 208 94 193 88 148 89 148 143
Polygon -6459832 true true 75 152 81 131 82 123 82 119 77 103 90 96 107 88 152 89 152 143
Polygon -8630108 true false 143 108 212 125 200 97 191 152 205 113 224 108 153 97 151 144 146 99 170 127 207 98 160 153 217 100 185 138 180 93 150 154 169 94 210 141 144 122 169 166 192 96 173 153 189 149
Polygon -8630108 true false 157 108 88 125 100 97 108 152 95 113 76 108 147 97 149 144 154 99 130 127 93 98 136 153 83 100 119 127 120 93 150 154 131 94 91 141 156 122 125 171 108 96 124 151 111 149
Polygon -6459832 true true 211 138 218 145 228 146 234 141 236 133 236 123 233 117 229 112 222 107 213 104 205 108 202 116 204 127
Polygon -6459832 true true 90 137 83 144 73 145 67 140 65 132 65 122 68 116 72 111 79 106 88 103 96 107 99 115 97 126
Polygon -1184463 true false 231 135 225 140 218 139 214 134 213 125 216 116 221 113 229 116 232 124
Polygon -1184463 true false 69 135 75 140 82 139 86 134 87 125 84 116 79 113 71 116 68 124
Polygon -16777216 true false 231 130 223 128 215 127 216 121 224 124 227 125 232 124 229 134
Polygon -16777216 true false 71 131 77 128 85 127 84 121 76 124 73 125 68 124 71 134
Polygon -8630108 true false 143 280 122 255 145 215 131 182 151 140 165 183 153 215 174 255 174 255 155 280 150 319

octobackup2
true
3
Polygon -6459832 true true 202 138 215 146 224 151 230 159 235 167 240 175 244 187 246 199 247 214 246 224 244 240 240 259 234 276 228 289 220 301 213 310 205 319 196 328 188 334 179 340 168 344 145 344 143 318 144 259 145 219 147 142 168 137 186 134
Polygon -6459832 true true 94 139 81 147 72 152 66 160 61 168 56 176 52 188 50 200 49 215 50 225 52 241 56 260 62 277 68 290 76 302 83 311 91 320 100 329 108 335 117 341 128 345 151 345 153 319 152 260 151 220 149 143 128 138 110 135
Polygon -6459832 true true 226 151 220 130 219 122 219 118 226 96 209 89 182 75 150 69 149 142
Polygon -6459832 true true 75 152 81 131 82 123 82 119 77 98 90 91 118 74 151 69 152 143
Polygon -8630108 true false 86 112 79 106 70 107 61 108 53 111 46 122 46 138 48 150 53 159 60 162 69 163 77 161 83 155 89 149 93 139 95 132 94 119
Polygon -8630108 true false 215 112 222 106 230 106 240 108 248 111 255 122 255 138 253 150 248 159 241 162 232 163 224 161 218 155 212 149 208 139 206 132 207 119
Polygon -8630108 true false 62 207 134 234 114 149 133 316 70 193 75 166 135 259 57 230 67 270 100 161 99 321 132 294 118 335 107 157 88 314 134 268 74 283 84 250 129 333 86 301
Polygon -8630108 true false 234 205 162 235 182 147 163 314 226 191 219 164 161 257 239 228 229 268 196 159 197 319 164 292 178 333 189 155 208 312 162 266 222 281 212 248 167 331 210 299
Polygon -8630108 true false 146 78 209 127 190 84 189 154 202 115 221 110 156 75 183 164 133 122 167 129 201 91 161 155 214 102 171 120 182 81 147 156 170 78 206 143 144 84 172 173 206 94 173 153 186 151
Polygon -8630108 true false 143 280 122 255 145 215 131 182 151 140 165 183 153 215 174 255 174 255 155 280 150 319
Polygon -1184463 true false 222 116 217 124 216 133 217 141 221 148 228 153 236 156 242 154 247 148 250 139 250 126 247 120 241 115 232 113
Polygon -1184463 true false 78 116 83 124 84 133 83 141 79 148 72 153 64 156 58 154 53 148 50 139 50 126 53 120 59 115 68 113
Polygon -16777216 true false 248 130 241 132 231 130 226 129 220 125 218 132 219 135 222 133 226 133 234 135 242 137 247 141 247 139 247 135
Polygon -16777216 true false 52 130 59 132 69 130 74 129 80 125 82 132 81 135 78 133 74 133 66 135 58 137 53 141 53 139 53 135
Polygon -8630108 true false 154 78 91 127 110 84 111 154 98 115 79 110 144 75 117 164 167 122 133 129 99 91 139 155 86 102 129 120 118 81 153 156 130 78 94 143 156 84 128 173 94 94 127 153 114 151

octobackup3
true
3
Polygon -6459832 true true 225 180 220 130 223 126 226 122 232 100 209 89 182 75 150 69 150 165
Polygon -6459832 true true 75 180 80 130 78 128 76 120 69 103 91 89 118 75 150 69 150 165
Polygon -6459832 true true 202 153 215 161 224 166 230 174 235 182 240 190 244 202 246 214 247 229 246 239 244 255 240 274 234 291 228 304 220 316 213 325 205 334 196 343 188 349 179 355 168 359 145 359 143 333 144 274 145 234 147 157 168 152 186 149
Polygon -6459832 true true 94 154 81 162 72 167 66 175 61 183 56 191 52 203 50 215 49 230 50 240 52 256 56 275 62 292 68 305 76 317 83 326 91 335 100 344 108 350 117 356 128 360 151 360 153 334 152 275 151 235 149 158 128 153 110 150
Polygon -8630108 true false 86 127 79 121 70 122 61 123 53 126 46 137 46 153 48 165 53 174 60 177 69 178 77 176 83 170 89 164 93 154 95 147 94 134
Polygon -8630108 true false 215 127 222 121 230 121 240 123 248 126 255 137 255 153 253 165 248 174 241 177 232 178 224 176 218 170 212 164 208 154 206 147 207 134
Polygon -8630108 true false 62 222 134 249 114 164 133 331 70 208 75 181 135 274 57 245 67 285 100 176 99 336 132 309 118 350 107 172 88 329 134 283 74 298 84 265 129 348 86 316
Polygon -8630108 true false 234 220 162 250 182 162 163 329 226 206 219 179 161 272 239 243 229 283 196 174 197 334 164 307 178 348 189 170 208 327 162 281 222 296 212 263 167 346 210 314
Polygon -8630108 true false 146 78 209 127 190 84 189 154 202 115 221 110 156 75 183 164 133 122 167 129 201 91 161 155 214 102 171 120 182 81 147 156 170 78 206 143 144 84 172 173 206 94 173 153 186 151
Polygon -8630108 true false 143 295 122 270 145 230 131 197 151 155 165 198 153 230 174 270 174 270 155 295 150 334
Polygon -1184463 true false 222 131 217 139 216 148 217 156 221 163 228 168 236 171 242 169 247 163 250 154 250 141 247 135 241 130 232 128
Polygon -1184463 true false 78 131 83 139 84 148 83 156 79 163 72 168 64 171 58 169 53 163 50 154 50 141 53 135 59 130 68 128
Polygon -16777216 true false 248 145 241 147 231 145 226 144 220 140 218 147 219 150 222 148 226 148 234 150 242 152 247 156 247 154 247 150
Polygon -16777216 true false 52 145 59 147 69 145 74 144 80 140 82 147 81 150 78 148 74 148 66 150 58 152 53 156 53 154 53 150
Polygon -8630108 true false 154 78 91 127 110 84 111 154 98 115 79 110 144 75 117 164 167 122 133 129 99 91 139 155 86 102 129 120 118 81 153 156 130 78 94 143 156 84 128 173 94 94 127 153 114 151

octobody
true
2
Polygon -8630108 true false 85 158 72 186 61 198 41 205 23 199 6 189 -2 177 -6 163 2 147 14 137 29 128 39 121 44 114 54 99 55 84 51 71 50 68 49 61 49 44 50 35 58 26 48 33 44 48 43 57 43 66 43 73 45 83 41 93 35 99 26 108 20 113 11 118 2 124 -13 136 -19 146 -28 168 -26 183 -19 202 -9 212 0 218 10 223 34 229 56 229 76 223 90 214 97 204 111 173
Polygon -6459832 true false 94 161 81 153 72 148 66 140 61 132 56 124 52 112 50 100 49 85 50 75 52 59 56 40 62 23 68 10 76 -2 83 -11 91 -20 100 -29 108 -35 117 -41 128 -45 151 -45 153 -19 152 40 151 80 149 157 128 162 110 165
Polygon -6459832 true false 202 162 215 154 224 149 230 141 235 133 240 125 244 113 246 101 247 86 246 76 244 60 240 41 234 24 228 11 220 -1 213 -10 205 -19 196 -28 188 -34 179 -40 168 -44 145 -44 143 -18 144 41 145 81 147 158 168 163 186 166
Polygon -11221820 true false 62 93 134 66 114 151 133 -16 70 107 75 134 135 41 57 70 67 30 100 139 99 -21 132 6 118 -35 107 143 88 -14 134 32 74 17 84 50 129 -33 86 -1
Polygon -11221820 true false 234 95 162 65 182 153 163 -14 226 109 219 136 161 43 239 72 229 32 196 141 197 -19 164 8 178 -33 189 145 208 -12 162 34 222 19 212 52 167 -31 210 1
Polygon -6459832 true false 225 148 219 169 218 177 218 181 225 193 208 206 193 212 148 211 148 157
Polygon -6459832 true false 74 149 80 170 81 178 81 182 74 194 91 207 106 213 151 212 151 158
Polygon -11221820 true false 143 192 212 175 200 203 194 158 205 187 224 192 153 203 151 156 146 201 170 173 207 202 164 147 217 200 181 173 180 207 150 146 169 206 206 170 144 178 187 149 192 204 173 148 189 151
Polygon -11221820 true false 157 192 88 175 100 203 106 158 95 187 76 192 147 203 149 156 154 201 130 173 93 202 136 147 83 200 119 173 120 207 150 146 131 206 94 170 156 178 113 149 108 204 124 149 111 151

octobody2
true
3
Polygon -6459832 true true 75 210 80 160 73 139 63 122 76 100 99 84 127 78 154 75 150 195
Polygon -6459832 true true 225 210 213 173 227 143 237 122 224 100 201 84 173 78 146 75 150 195
Polygon -6459832 true true 202 183 215 191 224 196 230 204 235 212 240 220 244 232 246 244 247 259 246 269 244 285 240 304 234 321 228 334 220 346 213 355 205 364 196 373 188 379 179 385 168 389 145 389 143 363 144 304 145 264 147 187 168 182 186 179
Polygon -6459832 true true 94 184 81 192 72 197 66 205 61 213 56 221 52 233 50 245 49 260 50 270 52 286 56 305 62 322 68 335 76 347 83 356 91 365 100 374 108 380 117 386 128 390 151 390 153 364 152 305 151 265 149 188 128 183 110 180
Polygon -11221820 true false 86 157 79 151 70 152 61 153 53 156 46 167 46 183 48 195 53 204 60 207 69 208 77 206 83 200 89 194 93 184 95 177 94 164
Polygon -11221820 true false 215 157 222 151 230 151 240 153 248 156 255 167 255 183 253 195 248 204 241 207 232 208 224 206 218 200 212 194 208 184 206 177 207 164
Polygon -11221820 true false 62 252 134 279 114 194 133 361 70 238 75 211 135 304 57 275 67 315 100 206 99 366 132 339 118 380 107 202 88 359 134 313 74 328 84 295 129 378 86 346
Polygon -11221820 true false 234 250 162 280 182 192 163 359 226 236 219 209 161 302 239 273 229 313 196 204 197 364 164 337 178 378 189 200 208 357 162 311 222 326 212 293 167 376 210 344
Polygon -11221820 true false 146 108 209 157 190 114 189 184 202 145 221 140 156 105 183 194 133 152 167 159 201 121 161 185 214 132 171 150 182 111 147 186 170 108 206 173 144 114 172 203 206 124 173 183 186 181
Polygon -11221820 true false 143 325 122 300 145 260 131 227 151 185 165 228 153 260 174 300 174 300 155 325 150 364
Polygon -1184463 true false 222 161 217 169 216 178 217 186 221 193 228 198 236 201 242 199 247 193 250 184 250 171 247 165 241 160 232 158
Polygon -1184463 true false 78 161 83 169 84 178 83 186 79 193 72 198 64 201 58 199 53 193 50 184 50 171 53 165 59 160 68 158
Polygon -16777216 true false 248 175 241 177 231 175 226 174 220 170 218 177 219 180 222 178 226 178 234 180 242 182 247 186 247 184 247 180
Polygon -16777216 true false 52 175 59 177 69 175 74 174 80 170 82 177 81 180 78 178 74 178 66 180 58 182 53 186 53 184 53 180
Polygon -11221820 true false 154 108 91 157 110 114 111 184 98 145 79 140 144 105 117 194 167 152 133 159 99 121 139 185 86 132 129 150 118 111 153 186 130 108 94 173 156 114 128 203 94 124 127 183 114 181

octopus
true
0
Polygon -7500403 true true 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -2064490 true false 165 60 60
Circle -2064490 true false 75 60 60
Polygon -7500403 true true 225 150 285 195 285 285 270 300 270 210 180 165
Rectangle -16777216 true false 90 75 120 90
Rectangle -16777216 true false 180 75 210 90
Polygon -7500403 true true 90 180 45 210 45 270 60 285 60 225 135 180
Polygon -7500403 true true 210 180 255 210 255 270 240 285 240 225 165 180
Polygon -7500403 true true 75 150 15 195 15 285 30 300 30 210 120 165
Polygon -7500403 true true 150 195 180 285 195 270 180 225 180 180
Polygon -7500403 true true 210 195 225 300 210 285 195 225 165 180
Polygon -7500403 true true 150 195 120 285 105 270 120 225 120 180
Polygon -7500403 true true 90 195 75 300 90 285 105 225 135 180

pebble
true
0
Polygon -7500403 true true 250 86 239 69 221 64 209 49 168 29 133 38 104 45 82 63 52 84 40 124 30 161 40 205 70 243 112 249 146 259 205 251 228 228 256 211 266 180 276 153 271 122 257 108
Polygon -6459832 true false 184 76 165 52 161 66 127 67 158 86 94 100 127 111 130 126 80 159 105 163 147 159 127 213 150 193 172 171 194 165 208 200 228 182 232 152 237 135 250 131 243 112 226 106 227 83 207 67 190 60

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

pleuro
true
0
Polygon -7500403 true true 135 285 165 285 210 240 240 165 225 105 210 90 195 75 105 75 90 90 75 105 60 165 90 240
Polygon -7500403 true true 150 60 240 60 210 105 90 105 60 60
Polygon -7500403 true true 195 120 255 90 195 90
Polygon -7500403 true true 105 120 45 90 105 90

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
