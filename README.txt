SkuMapper Addon

This addon is used to build and edit map data for the Sku addon.
For more information join the Sku Discord server: https://discord.gg/FsfKeqxZV4

------------------------------------------------
Key bindings (no default bindings, set them up via Game Settings > Interface > Key bindings > Other)
	Open Sku minimap
	Add normal waypoint (same as CTRL + LEFT MOUSE)
	Add large waypoint
	NEW Select waypoints under mouse (same as CTRL + ALT + MIDDLE MOUSE)
	Rename an existing waypoint (same as CTRL + MIDDLE MOUSE)
	Cancel current recording/deleting	
	Show map data on default game minimap
	Toggle default game minimap size

------------------------------------------------
Mouse buttons
	Creating...
		CTRL + LEFT MOUSE
			Start/end creating a new link
		CTRL + SHIFT +	LEFT MOUSE
			Create a new custom waypoint
		CTRL + SHIFT + ALT + LEFT MOUSE	
			Add a new comment to an existing waypoint

	Deleting...
		CTRL + RIGHT MOUSE
			Start/end deleting an existing link
		CTRL + SHIFT + RIGHT MOUSE
			Delete an existing custom waypoint
		CTRL + ALT + RIGHT MOUSE
			Delete all comments from an existing waypoint

	Modifing...
		CTRL + MIDDLE MOUSE
			Rename an existing custom waypoint
		CTRL + MOUSE 4
			Hold and drag to move an existing waypoint

	NEW Selecting...
		CTRL + ALT + MIDDLE MOUSE
			In selection mode "mouse over": toggle selection for all mouse over waypoints
			In selection mode "start / end": set start point for selected routes
		CTRL + ALT + LEFT MOUSE
			In selection mode "start / end": set additional end point for selected routes

------------------------------------------------
Slash commands
	/sku import	import a text file with map data
	/sku export	output the map data for the text file
	/sku follow	set the sku minimap to follow
	/sku reset	reset all map data to the the default data (caution: all your work will be lost)
	/sku version	output the addon version
	/sku mmreset	reset the size and position of the sku minimap

------------------------------------------------
Release notes

r3
	- Update to new map data structure and interface with named auto waypoints and layers for waypoints

r2.4
	- Updated the toc for Ulduar patch.

r2.3
	- There is a new input box to enter filter terms for waypoints. Found waypoints are shown in white with double size.

r2.2
	- Object waypoints (green): first 3 are now shown in yellow and the "limit" filter is applied to them
	- Added a check for existing names on renaming waypoints

r2.1
	- Added player coords to map

r2
	- Added updated data to item, quest, creature and object databases

r1.9
	- Fixed the missing sounds

r1.8
	- Fixed incorrect path data

r1.7
	- Fixed missing SkuDB link

r1.6
	- Bug fixes
	- Removed controls for recording special areas

r1.5
	- Added sounds
	- Added a key bind to cancel the current action (recording/deleting)