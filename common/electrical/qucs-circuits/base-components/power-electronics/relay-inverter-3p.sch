<Qucs Schematic 0.0.18>
<Properties>
  <View=-7,-70,1155,761,1.01227,35,0>
  <Grid=10,10,1>
  <DataSet=relay-inverter-3p.dat>
  <DataDisplay=relay-inverter-3p.dpl>
  <OpenDisplay=1>
  <Script=relay-inverter-3p.m>
  <RunScript=0>
  <showFrame=0>
  <FrameText0=Title>
  <FrameText1=Drawn By:>
  <FrameText2=Date:>
  <FrameText3=Revision:>
</Properties>
<Symbol>
  <Line -20 -160 270 0 #000080 2 1>
  <Line -20 -160 0 160 #000080 2 1>
  <.PortSym -30 -130 1 0>
  <Line -30 -130 10 0 #000080 2 1>
  <.PortSym -30 -30 3 0>
  <Line -30 -30 10 0 #000080 2 1>
  <Line -20 -80 -10 0 #000080 2 1>
  <.PortSym -30 -80 2 0>
  <Text 170 -60 16 #00007f 0 "DC">
  <Text -10 -150 16 #00007f 0 "AC">
  <Line 0 -60 30 0 #000000 0 1>
  <Line 30 -60 50 -20 #000000 0 1>
  <Line 80 -60 40 0 #000000 0 1>
  <Line 60 -80 0 -30 #000000 0 1>
  <Line 60 -110 40 0 #000000 0 1>
  <.PortSym -10 10 6 0>
  <Line -10 10 0 -10 #000080 2 1>
  <.PortSym 40 10 7 0>
  <Line 40 10 0 -10 #000080 2 1>
  <.PortSym 90 10 8 0>
  <Line 90 10 0 -10 #000080 2 1>
  <.PortSym 140 10 9 0>
  <Line 140 10 0 -10 #000080 2 1>
  <.PortSym 190 10 10 0>
  <Line 190 10 0 -10 #000080 2 1>
  <.PortSym 240 10 11 0>
  <Line 250 -160 0 160 #000080 2 1>
  <Line 250 -120 10 0 #000080 2 1>
  <.PortSym 260 -120 4 180>
  <.PortSym 260 -40 5 180>
  <Line 260 -40 -10 0 #000080 2 1>
  <Line 250 -160 -160 160 #000000 0 1>
  <Line -20 0 270 0 #000080 2 1>
  <Line 240 10 0 -10 #000080 2 1>
  <.ID 260 -16 RELAYACDC "1=VS_thresh=1 V=Relay Threshold Voltage=Voltage" "1=VS_hyst=0.001=Hysterysis Voltage=Voltage" "1=R_on=1e-6=Relay resistance when on=Resistance" "1=R_off=1e6=Relay resistance when off=Resistance">
</Symbol>
<Components>
  <Port A 1 20 220 -23 12 0 0 "1" 1 "analog" 0>
  <Port B 1 20 280 -23 12 0 0 "2" 1 "analog" 0>
  <Port C 1 20 340 -23 12 0 0 "3" 1 "analog" 0>
  <Port SC2 1 90 400 -23 12 0 0 "7" 1 "analog" 0>
  <Relais S2 1 180 430 49 -26 0 0 "VS_thresh" 0 "VS_hyst" 0 "R_on" 0 "R_off" 0 "26.85" 0>
  <Diode D2 1 340 430 -74 -26 0 3 "1e-15 A" 1 "1" 1 "10 fF" 1 "0.5" 0 "0.7 V" 0 "0.5" 0 "0.0 fF" 0 "0.0" 0 "2.0" 0 "0.0 Ohm" 0 "0.0 ps" 0 "0" 0 "0.0" 0 "1.0" 0 "1.0" 0 "0" 0 "1 mA" 0 "26.85" 0 "3.0" 0 "1.11" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "26.85" 0 "1.0" 0 "normal" 0>
  <GND * 1 820 460 0 0 0 0>
  <Port SC6 1 760 400 -23 12 0 0 "11" 1 "analog" 0>
  <Relais S6 1 850 430 49 -26 0 0 "VS_thresh" 0 "VS_hyst" 0 "R_on" 0 "R_off" 0 "26.85" 0>
  <GND * 1 470 460 0 0 0 0>
  <Port SC4 1 410 400 -23 12 0 0 "9" 1 "analog" 0>
  <Relais S4 1 500 430 49 -26 0 0 "VS_thresh" 0 "VS_hyst" 0 "R_on" 0 "R_off" 0 "26.85" 0>
  <Diode D4 1 660 430 -74 -26 0 3 "1e-15 A" 1 "1" 1 "10 fF" 1 "0.5" 0 "0.7 V" 0 "0.5" 0 "0.0 fF" 0 "0.0" 0 "2.0" 0 "0.0 Ohm" 0 "0.0 ps" 0 "0" 0 "0.0" 0 "1.0" 0 "1.0" 0 "0" 0 "1 mA" 0 "26.85" 0 "3.0" 0 "1.11" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "26.85" 0 "1.0" 0 "normal" 0>
  <Diode D6 1 1010 430 -74 -26 0 3 "1e-15 A" 1 "1" 1 "10 fF" 1 "0.5" 0 "0.7 V" 0 "0.5" 0 "0.0 fF" 0 "0.0" 0 "2.0" 0 "0.0 Ohm" 0 "0.0 ps" 0 "0" 0 "0.0" 0 "1.0" 0 "1.0" 0 "0" 0 "1 mA" 0 "26.85" 0 "3.0" 0 "1.11" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "26.85" 0 "1.0" 0 "normal" 0>
  <Port DCminus 1 1040 520 4 -42 0 2 "5" 1 "analog" 0>
  <Diode D1 1 330 130 -74 -26 0 3 "1e-15 A" 1 "1" 1 "10 fF" 1 "0.5" 0 "0.7 V" 0 "0.5" 0 "0.0 fF" 0 "0.0" 0 "2.0" 0 "0.0 Ohm" 0 "0.0 ps" 0 "0" 0 "0.0" 0 "1.0" 0 "1.0" 0 "0" 0 "1 mA" 0 "26.85" 0 "3.0" 0 "1.11" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "26.85" 0 "1.0" 0 "normal" 0>
  <GND * 1 150 160 0 0 0 0>
  <Port SC1 1 90 100 -23 12 0 0 "6" 1 "analog" 0>
  <Relais S1 1 180 130 49 -26 0 0 "VS_thresh" 0 "VS_hyst" 0 "R_on" 0 "R_off" 0 "26.85" 0>
  <GND * 1 470 160 0 0 0 0>
  <Port SC3 1 410 100 -23 12 0 0 "8" 1 "analog" 0>
  <Relais S3 1 500 130 49 -26 0 0 "VS_thresh" 0 "VS_hyst" 0 "R_on" 0 "R_off" 0 "26.85" 0>
  <Diode D3 1 660 130 -74 -26 0 3 "1e-15 A" 1 "1" 1 "10 fF" 1 "0.5" 0 "0.7 V" 0 "0.5" 0 "0.0 fF" 0 "0.0" 0 "2.0" 0 "0.0 Ohm" 0 "0.0 ps" 0 "0" 0 "0.0" 0 "1.0" 0 "1.0" 0 "0" 0 "1 mA" 0 "26.85" 0 "3.0" 0 "1.11" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "26.85" 0 "1.0" 0 "normal" 0>
  <GND * 1 820 160 0 0 0 0>
  <Port SC5 1 760 100 -23 12 0 0 "10" 1 "analog" 0>
  <Relais S5 1 850 130 49 -26 0 0 "VS_thresh" 0 "VS_hyst" 0 "R_on" 0 "R_off" 0 "26.85" 0>
  <Diode D5 1 1010 130 -74 -26 0 3 "1e-15 A" 1 "1" 1 "10 fF" 1 "0.5" 0 "0.7 V" 0 "0.5" 0 "0.0 fF" 0 "0.0" 0 "2.0" 0 "0.0 Ohm" 0 "0.0 ps" 0 "0" 0 "0.0" 0 "1.0" 0 "1.0" 0 "0" 0 "1 mA" 0 "26.85" 0 "3.0" 0 "1.11" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "0.0" 0 "26.85" 0 "1.0" 0 "normal" 0>
  <Port DCplus 1 1040 70 4 -42 0 2 "4" 1 "analog" 0>
  <GND * 1 150 460 0 0 0 0>
</Components>
<Wires>
  <20 220 210 220 "" 0 0 0 "">
  <20 340 880 340 "" 0 0 0 "">
  <20 280 530 280 "" 0 0 0 "">
  <530 280 530 400 "" 0 0 0 "">
  <880 340 880 400 "" 0 0 0 "">
  <210 220 210 400 "" 0 0 0 "">
  <90 400 150 400 "" 0 0 0 "">
  <210 400 340 400 "" 0 0 0 "">
  <760 400 820 400 "" 0 0 0 "">
  <410 400 470 400 "" 0 0 0 "">
  <880 400 1010 400 "" 0 0 0 "">
  <530 400 660 400 "" 0 0 0 "">
  <1010 460 1010 520 "" 0 0 0 "">
  <210 460 210 520 "" 0 0 0 "">
  <210 520 340 520 "" 0 0 0 "">
  <340 460 340 520 "" 0 0 0 "">
  <340 520 530 520 "" 0 0 0 "">
  <530 460 530 520 "" 0 0 0 "">
  <530 520 660 520 "" 0 0 0 "">
  <660 460 660 520 "" 0 0 0 "">
  <660 520 880 520 "" 0 0 0 "">
  <880 520 1010 520 "" 0 0 0 "">
  <880 460 880 520 "" 0 0 0 "">
  <1010 520 1040 520 "" 0 0 0 "">
  <1010 70 1010 100 "" 0 0 0 "">
  <90 100 150 100 "" 0 0 0 "">
  <210 160 210 190 "" 0 0 0 "">
  <410 100 470 100 "" 0 0 0 "">
  <760 100 820 100 "" 0 0 0 "">
  <530 70 530 100 "" 0 0 0 "">
  <530 70 660 70 "" 0 0 0 "">
  <660 70 660 100 "" 0 0 0 "">
  <660 70 880 70 "" 0 0 0 "">
  <880 70 880 100 "" 0 0 0 "">
  <880 70 1010 70 "" 0 0 0 "">
  <530 160 530 190 "" 0 0 0 "">
  <530 190 530 280 "" 0 0 0 "">
  <530 190 660 190 "" 0 0 0 "">
  <660 160 660 190 "" 0 0 0 "">
  <880 160 880 190 "" 0 0 0 "">
  <880 190 880 340 "" 0 0 0 "">
  <880 190 1010 190 "" 0 0 0 "">
  <1010 160 1010 190 "" 0 0 0 "">
  <330 70 330 100 "" 0 0 0 "">
  <330 70 530 70 "" 0 0 0 "">
  <210 70 210 100 "" 0 0 0 "">
  <210 70 330 70 "" 0 0 0 "">
  <1010 70 1040 70 "" 0 0 0 "">
  <330 160 330 190 "" 0 0 0 "">
  <210 190 210 220 "" 0 0 0 "">
  <210 190 330 190 "" 0 0 0 "">
</Wires>
<Diagrams>
</Diagrams>
<Paintings>
</Paintings>
