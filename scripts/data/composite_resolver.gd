class_name CompositeResolver
extends RefCounted

## Builds a display plan for a character slot.
## mode "composite": one pre-baked sprite centered in the card.
## mode "layered": place head/body/legs at fixed anchors on the card.
static func resolve(character: CharacterDef, has_head: bool, has_body: bool, has_legs: bool) -> Dictionary:
	var empty := {
		"mode": "empty",
		"composite": null,
		"composite_kind": "",
		"head": null,
		"body": null,
		"legs": null,
	}
	if character == null:
		return empty

	if has_head and has_body and has_legs and character.full_sprite != null:
		return {
			"mode": "composite",
			"composite": character.full_sprite,
			"composite_kind": "full",
			"head": null,
			"body": null,
			"legs": null,
		}

	if has_head and has_body and not has_legs and character.body_head_sprite != null:
		return {
			"mode": "composite",
			"composite": character.body_head_sprite,
			"composite_kind": "body_head",
			"head": null,
			"body": null,
			"legs": null,
		}

	if has_body and has_legs and not has_head and character.body_legs_sprite != null:
		return {
			"mode": "composite",
			"composite": character.body_legs_sprite,
			"composite_kind": "body_legs",
			"head": null,
			"body": null,
			"legs": null,
		}

	return {
		"mode": "layered",
		"composite": null,
		"composite_kind": "",
		"head": character.head.sprite if has_head and character.head != null else null,
		"body": character.body.sprite if has_body and character.body != null else null,
		"legs": character.legs.sprite if has_legs and character.legs != null else null,
	}
