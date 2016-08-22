#find all the synchronizers
set synchronizers [get_cells -hier -filter {(ORIG_REF_NAME == synchronizer) || (REF_NAME == synchronizer)}]

foreach sync $synchronizers {
	#set ASYNC_REG on the sync and guard flip-flops
	set_property ASYNC_REG TRUE [get_cells $sync/s_data_*]
	# false path to asynchronous preset or clear on all flip-flops in chain
	set_false_path -to [get_pins -regexp "$sync/s_data_.*/(PRE|CLR)"]
	# false path to sync data
	set_false_path -to [get_pins $sync/s_data_sync_r*/D]
	# max delay to maximize metastability settle time
	set_max_delay -from [get_cells $sync/s_data_sync_r*] -to [get_cells $sync/s_data_guard_r_reg[0]] 2
}
