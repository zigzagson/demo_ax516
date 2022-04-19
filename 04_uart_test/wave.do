onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /uart_test_tb/clk
add wave -noupdate /uart_test_tb/rst_n
add wave -noupdate /uart_test_tb/uart_rx
add wave -noupdate /uart_test_tb/uart_tx
add wave -noupdate /uart_test_tb/i
add wave -noupdate /glbl/GSR
add wave -noupdate -radix hexadecimal /uart_test_tb/uut/rx_data
add wave -noupdate /uart_test_tb/uut/rx_data_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {46378250 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 213
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {223333360 ps}
