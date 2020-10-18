set output_dir "outputs/"

open_checkpoint $output_dir/post_place.dcp

route_design

write_checkpoint -force $output_dir/post_route
report_timing_summary -file $output_dir/post_route_timing_summary.rpt
write_bitstream  -force $output_dir/hardcaml_arty_top.bit
