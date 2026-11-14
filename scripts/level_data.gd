extends RefCounted
# Level layouts. Everything is measured in 16px tiles.
#   solid   : [x, y, w, h]  solid blocks (ground, mounds, pillars)
#   plat    : [x, y, w]     one-way floating platforms (w is 3 or 6)
#   player  : [x, y]        tile Verity stands ON (feet at the top of that tile)
#   chef    : [x, y]        tile the chef stands on
#   soldiers: [[x, y], ...] tiles soldiers stand on
#   decor   : [name, x, y]  background scenery standing on tile row y
# "theme" picks the tileset look + sky: 0 grass/day, 1 sand/sunset, 2 stone/night

const LEVELS = [
	{
		"name": "Level 1",
		"cols": 48,
		"rows": 23,
		"theme": 0,
		"solid": [[0, 20, 48, 3], [21, 18, 6, 2]],
		"plat": [[6, 17, 6], [13, 14, 3], [36, 17, 6], [30, 14, 3]],
		"player": [3, 20],
		"chef": [24, 18],
		"soldiers": [[15, 20], [38, 17], [44, 20]],
		"decor": [
			["tree", 1, 20], ["sign", 5, 20], ["mush_o", 12, 20], ["bush", 19, 20],
			["tree_o", 28, 20], ["mush_r", 31, 20], ["tree", 33, 20], ["bush", 42, 20],
			["tree_t", 46, 20]
		],
	},
	{
		"name": "Level 2",
		"cols": 60,
		"rows": 23,
		"theme": 1,
		"solid": [[0, 20, 60, 3], [13, 17, 3, 3], [44, 17, 3, 3], [26, 17, 8, 3]],
		"plat": [[6, 17, 3], [20, 17, 3], [38, 17, 3], [51, 17, 3], [10, 14, 3], [22, 14, 3], [36, 14, 3], [50, 14, 3]],
		"player": [3, 20],
		"chef": [30, 17],
		"soldiers": [[9, 20], [21, 17], [39, 17], [52, 14], [57, 20]],
		"decor": [
			["tree_o", 2, 20], ["mush_o", 5, 20], ["tree_o", 17, 20], ["mush_p", 23, 20],
			["tree_o", 35, 20], ["mush_r", 41, 20], ["tree_o", 49, 20], ["mush_o", 55, 20],
			["sign", 59, 20]
		],
	},
	{
		"name": "Level 3",
		"cols": 72,
		"rows": 23,
		"theme": 2,
		"solid": [[0, 20, 72, 3], [12, 17, 4, 3], [28, 17, 3, 3], [41, 17, 3, 3], [33, 18, 7, 2], [58, 17, 4, 3]],
		"plat": [[4, 17, 3], [18, 17, 3], [47, 17, 3], [65, 17, 3], [8, 14, 3], [22, 14, 3], [51, 14, 3], [68, 14, 3], [25, 11, 3], [54, 11, 3]],
		"player": [2, 20],
		"chef": [36, 18],
		"soldiers": [[14, 17], [19, 17], [23, 14], [29, 17], [42, 17], [52, 14], [66, 17]],
		"decor": [
			["tree_t", 1, 20], ["mush_p", 7, 20], ["tree_t", 10, 20], ["mush_t", 25, 20],
			["tree_t", 31, 20], ["mush_p", 45, 20], ["tree_t", 55, 20], ["mush_t", 63, 20],
			["tree_t", 70, 20]
		],
	},
]
