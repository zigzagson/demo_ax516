

 
 
 




window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"

      waveform add -signals /icmp_rx_ram_8_256_tb/status
      waveform add -signals /icmp_rx_ram_8_256_tb/icmp_rx_ram_8_256_synth_inst/bmg_port/CLKA
      waveform add -signals /icmp_rx_ram_8_256_tb/icmp_rx_ram_8_256_synth_inst/bmg_port/ADDRA
      waveform add -signals /icmp_rx_ram_8_256_tb/icmp_rx_ram_8_256_synth_inst/bmg_port/DINA
      waveform add -signals /icmp_rx_ram_8_256_tb/icmp_rx_ram_8_256_synth_inst/bmg_port/WEA
      waveform add -signals /icmp_rx_ram_8_256_tb/icmp_rx_ram_8_256_synth_inst/bmg_port/CLKB
      waveform add -signals /icmp_rx_ram_8_256_tb/icmp_rx_ram_8_256_synth_inst/bmg_port/ADDRB
      waveform add -signals /icmp_rx_ram_8_256_tb/icmp_rx_ram_8_256_synth_inst/bmg_port/DOUTB

console submit -using simulator -wait no "run"
