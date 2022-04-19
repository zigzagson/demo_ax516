
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name rtc_ds1302 -dir "E:/BaiduYunDownload/AX516.190526/demo/07_rtc_ds1302/planAhead_run_4" -part xc6slx16csg324-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "E:/BaiduYunDownload/AX516.190526/demo/07_rtc_ds1302/top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {E:/BaiduYunDownload/AX516.190526/demo/07_rtc_ds1302} }
set_property target_constrs_file "rtc_ds1302.ucf" [current_fileset -constrset]
add_files [list {rtc_ds1302.ucf}] -fileset [get_property constrset [current_run]]
link_design
