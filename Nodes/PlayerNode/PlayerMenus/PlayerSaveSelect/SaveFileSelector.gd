extends FileSelector

func refresh_file_list():
	.refresh_file_list()
	# Remove currently used saves
	for path in O3DP.get_main().loaded_save_files:
		remove_file_item(path)
