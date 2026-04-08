extends Node

## 音频管理器

var _cached_sfx: Dictionary = {}

func play_sfx(sfx_name: String) -> void:
	if not sfx_name in _cached_sfx:
		_cached_sfx[sfx_name] = true
	print("[AudioManager] play_sfx: ", sfx_name)
	# TODO: 实现音效播放

func play_bgm(bgm_name: String) -> void:
	print("[AudioManager] play_bgm: ", bgm_name)
	# TODO: 实现背景音乐播放
