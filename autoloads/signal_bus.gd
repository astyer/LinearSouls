extends Node

signal player_damaged(damage: int)
signal boss_damaged(damage: int)

signal hit_player(damage: int, hitVelocity: int, requireOnFloor: bool)
signal hit_parry()

signal hit_boss(damage: int, hitVelocity: int)
