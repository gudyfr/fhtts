import re
import os

CardDescriptions = {
    # Brute
    "brp1": "+1",
    "brp3": "+3",
    "brpu": "+0, Push 1, Reroll",
    "brpi": "+0, Pierce 3, Reroll",
    "brst": "+0, Stun, Reroll",
    "brdi": "+0, Disarm, Reroll",
    "brmu": "+0, Muddle, Reroll",
    "brta": "+0, Add 1 Target, Reroll",
    "brsh": "+1, Shield 1 Self",
    # Spellweaver
    "spp1": "+1",
    "spst": "+0, Stun",
    "spwo": "+1, Wound",
    "spim": "+1, Immobilize",
    "spcu": "+1, Curse",
    "spfi": "+2, Infuse Fire",
    "spic": "+2, Infuse Ice",
    "spea": "+0, Infuse Earth, Reroll",
    "spwi": "+0, Infuse Wind, Reroll",
    "spli": "+0, Infuse Light, Reroll",
    "spda": "+0, Infuse Dark, Reroll",
    # Tinkerer
    "tip0": "+0",
    "tip1": "+1",
    "tip3": "+3",
    "tifi": "+0, Infuse Fire, Reroll",
    "timu": "+0, Muddle, Reroll",
    "tiwo": "+1, Wound",
    "tiim": "+1, Immobilize",
    "tih2": "+1, Heal 2 Self",
    "tiat": "+0, Add 1 Target",
    # Scoundrel
    "scp0": "+0",
    "scp1": "+1",
    "scp2": "+2",
    "sc1r": "+1, Reroll",
    "scpi": "+0, Pierce 3, Reroll",
    "scpo": "+0, Poison, Reroll",
    "scmu": "+0, Muddle, Reroll",
    "scin": "+0, Invisible Self, Reroll",
    # Cragheart
    "crp1": "+1",
    "crm2": "-2",
    "crp2": "+2",
    "crim": "+1, Immobilize",
    "crmu": "+2, Muddle",
    "crpu": "+0, Push 2, Reroll",
    "crea": "+0, Infuse Earth, Reroll",
    "crwi": "+0, Infuse Wind, Reroll",
    # Mindthief
    "mip2": "+2",
    "mip0": "+0",
    "miic": "+2, Infuse Ice",
    "mi1r": "+1, Reroll",
    "mipu": "+0, Pull 1, Reroll",
    "mimu": "+0, Muddle, Reroll",
    "miim": "+0, Immobilize, Reroll",
    "mist": "+0, Stun, Reroll",
    "midi": "+0, Disarm, Reroll",
    # Sunkeeper
    "sup0": "+0",
    "sup2": "+2",
    "su1r": "+1, Reroll",
    "suh1": "+0, Heal 1 Self, Reroll",
    "sust": "+0, Stun, Reroll",
    "suli": "+0, Infuse Light, Reroll",
    "sush": "+0, Shield 1 Self, Reroll",
    "sup1": "+1",
    # Soothsinger
    "sop4": "+4",
    "soim": "+1, Immobilize",
    "sodi": "+1, Disarm",
    "sowo": "+2, Wound",
    "sopo": "+2, Poison",
    "socu": "+2, Curse",
    "somu": "+3, Muddle",
    "sost": "+0, Stun",
    "so1r": "+1, Reroll",
    "socr": "+0, Curse, Reroll",
    # Sawbones
    "sa2r": "+2, Reroll",
    "sap2": "+2",
    "saim": "+1, Immobilize",
    "sawo": "+0, Wound, Reroll",
    "sast": "+0, Stun, Reroll",
    "sah3": "+0, Heal 3 Self, Reroll",
    "sare": "+0, Refresh an item",
    # Beast Tyrant
    "btp1": "+1",
    "btp2": "+2",
    "btwo": "+1, Wound",
    "btim": "+1, Immobilize",
    "bth1": "+0, Heal 1 Self, Reroll",
    "btea": "+0, Infuse Earth, Reroll",
    # Berserker
    "bep1": "+1",
    "bep2": "+2, Reroll",
    "bewo": "+0, Wound, Reroll",
    "best": "+0, Stun, Reroll",
    "bedi": "+1, Disarm, Reroll",
    "beh1": "+0, Heal 1 Self, Reroll",
    "befi": "+2, Infuse Fire",
    # Doomstalker
    "dop1": "+1",
    "do1r": "+1, Reroll",
    "domu": "+2, Muddle",
    "dopo": "+1, Poison",
    "dowo": "+1, Wound",
    "doim": "+1, Immobilize",
    "dost": "+0, Stun",
    "doat": "+0, Add 1 Target, Reroll",
    # Elementalist
    "elp1": "+1",
    "elp2": "+2",
    "elfi": "+0, Infuse Fire",
    "elic": "+0, Infuse Ice",
    "elwi": "+0, Infuse Wind",
    "elea": "+0, Infuse Earth",
    "elpu": "+1, Push 1",
    "elwo": "+1, Wound",
    "elst": "+0, Stun",
    "elta": "+0, Add 1 Target",
    # Nightshroud
    "nsda": "+1, Infuse Dark",
    "nsin": "+1, Invisible Self",
    "nsmu": "+0, Muddle, Reroll",
    "nsh1": "+0, Heal 1 Self, Reroll",
    "nscu": "+0, Curse, Reroll",
    "nsat": "+0, Add 1 Target, Reroll",
    "nsp1": "+1",
    "nsm1": "-1, Infuse Dark",
    # Plagueherald
    "plp0": "+0",
    "plp1": "+1",
    "plp2": "+2",
    "plwi": "+1, Infuse Wind",
    "plpo": "+0, Poison, Reroll",
    "plcu": "+0, Curse, Reroll",
    "plim": "+0, Immobilize, Reroll",
    "plst": "+0, Stun, Reroll",
    # Quartermaster
    "qmp2": "+2",
    "qm1r": "+1, Reroll",
    "qmmu": "+0, Muddle, Reroll",
    "qmpi": "+0, Pierce 3, Reroll",
    "qmst": "+0, Stun, Reroll",
    "qmat": "+0, Add 1 Target, Reroll",
    "qmre": "+0, Refresh an item",
    "qmp1": "+1",
    # Summoner
    "smp0": "+0",
    "smp1": "+1",
    "smp2": "+2",
    "smwo": "+0, Wound, Reroll",
    "smpo": "+0, Poison, Reroll",
    "smh1": "+0, Heal 1 Self, Reroll",
    "smfi": "+0, Infuse Fire, Reroll",
    "smwi": "+0, Infuse Wind, Reroll",
    "smda": "+0, Infuse Dark, Reroll",
    "smea": "+0, Infuse Earth, Reroll",
    # Diviner
    "dip1": "+1",
    "pip3": "+3, Shield 1 Self",
    "dida": "+2, Infuse Dark",
    "dili": "+2, Infuse Light",
    "dimu": "+3, Muddle",
    "dicu": "+2, Curse",
    "dire": "+2, Regenerate Self",
    "diha": "+1, Heal 2 Ally",
    "dih1": "+0, Heal 1 Self, Reroll",
    "dicr": "+0, Curse, Reroll",
    "disa": "+1, Shield 1 Ally",
    # Bladeswarm
    "blwi": "+1, Infuse Wind",
    "blea": "+1, Infuse Earth",
    "blli": "+1, Infuse Light",
    "blda": "+1, Infuse Dark",
    "blh1": "+0, Heal 1 Self, Reroll",
    "blwo": "+1, Wound",
    "blpo": "+1, Poison",
    "blmu": "+2, Muddle",
    "blp1": "+1",
    "blp0": "+0",
}


def getAttackModifiers(saveData):
    attackModifiers = {}
    exp = r'"Nickname":\s"Attack Modifier ([^"]*)",\n\s*"Description": "([^"]*)",'
    matches = re.findall(exp, saveData)
    for match in matches:
        className = match[1]
        attackModifier = match[0]
        if className not in attackModifiers:
            attackModifiers[className] = []
        if attackModifier not in attackModifiers[className]:
            attackModifiers[className].append([attackModifier, ""])
    return attackModifiers


my_path = "TS_Save_101.json"
o_path = (
    "C:\\Users\\ochal\\Documents\\My Games\\Tabletop Simulator\\Saves\\TS_Save_101.json"
)

mapping_class_name_to_short_name = {
    "Orchid Spellweaver": "sp",
    "Vermling Mindthief": "mi",
    "Savvas Cragheart": "cr",
    "Quatryl Tinkerer": "ti",
    "Inox Brute": "br",
    "Human Scoundrel": "sc",
    "Orchid Doomstalker": "do",
    "Plagueherald": "pl",
    "Aesther Nightshroud": "ns",
    "Savvas Elementalist": "el",
    "Valrath Quartermaster": "qm",
    "Vermling Beast Tyrant": "bt",
    "Quatryl Soothsinger": "so",
    "Valrath Sunkeeper": "su",
    "Human Sawbones": "sa",
    "Aesther Summoner": "sm",
    "Diviner": "di",
    "Bladeswarm": "bl",
}

attack_modifiers_name_by_class = {}
for class_name, short_name in mapping_class_name_to_short_name.items():
    attack_modifiers_name_by_class[class_name] = {}
    for desc_name, effect in CardDescriptions.items():
        if desc_name[:2] == short_name:
            attack_modifiers_name_by_class[class_name][desc_name] = effect
# print(attack_modifiers_name_by_class)


def map_group(group: str, UNMATCH_CARDS: list, class_name: str):
    match group:
        case "Darkness" | "Create Dark":
            return "Infuse Dark"
        case "Create Light":
            return "Infuse Light"
        case "Air":
            return "Infuse Wind"
        case "Light" | "Fire" | "Ice" | "Earth" | "Wind" | "Dark":
            return "Infuse " + group
        case "Heal +1" | "Heal 1 Self" | "Heal +1 Self":
            return "Heal 1 Self"
        case "Heal 3 Self":
            return group
        case "Heal 2 Self":
            return group
        case "Pierce 3":
            return group
        case "Shield 1 Self":
            return group
        case "Heal 2 Ally":
            return group
        case "Regenerate Self":
            return group
        case "Invisible" | "Invisibility":
            return "Invisible Self"
        case "Refresh":
            return "Refresh an item"
        case "Shield 1 Ally":
            return group
        case "+1" | "+2" | "+0" | "-1" | "-2" | "+3" | "+4":
            return group
        case "Rolling":
            return "Reroll"
        case "Wound" | "Poison" | "Immobilize" | "Muddle" | "Curse" | "Stun" | "Disarm":
            return group
        case "Pull 1" | "Push 1" | "Push 2":
            return group
        case "Add Target":
            return "Add 1 Target"
        case _:
            raise Exception("Group not matched")


def rename_cards_of_class(cards: list, class_name: str, UNMATCH_CARDS: list):
    renamed_cards = []
    for card in cards:
        renamed_cards.append(rename_card_of_class(card, class_name, UNMATCH_CARDS))
    return renamed_cards


def rename_card_of_class(card: str, class_name: str, UNMATCH_CARDS):
    pattern = r"\(([^\)]+)\)"
    groups = re.findall(pattern, card)
    mapped = []
    print(card, groups)
    if groups[0][0] != "+" and groups[0][0] != "-":
        mapped.append("+0")
    for group in groups:
        mapped.append(map_group(group, UNMATCH_CARDS, class_name))
    return ", ".join(mapped)


def map_card_to_short_name(attack_modifier, class_name):
    for short_name, desc in attack_modifiers_name_by_class[class_name].items():
        if desc == attack_modifier:
            return short_name


def rename_card(matchobj):
    class_name = matchobj.group(2)
    attack_modifier_card = matchobj.group(1)
    short_name = map_card_to_short_name(
        rename_card_of_class(attack_modifier_card, class_name, []), class_name
    )
    return f'"Nickname" : "", "Description" : "{short_name}", "Tags" : ["attack modifier"],'


def replaceAttackModifiers(saveData):
    exp = r'"Nickname":\s"Attack Modifier ([^"]*)",\n\s*"Description": "([^"]*)",'
    saveData = re.sub(exp, rename_card, saveData)
    return saveData


with open(o_path) as file:
    saveData = file.read()
    with open("TS_new_save.json", "w") as new_file:
        new_file.write(replaceAttackModifiers(saveData))
    # attackModifiers = getAttackModifiers(saveData)
    # UNMATCH_CARDS = []
    # for class_name in attackModifiers.keys():
    #     renamed_cards = rename_cards_of_class(
    #         attackModifiers[class_name], class_name, UNMATCH_CARDS
    #     )
    #     for renamed_card in renamed_cards:
    #         if renamed_card not in attack_modifiers_name_by_class[class_name].values():
    #             UNMATCH_CARDS.append((renamed_card, class_name))
    # print("UNMATCH_CARDS :", UNMATCH_CARDS)
    # # print("Bladeswarm", attackModifiers["Bladeswarm"])

# rename_cards_of_class(attackModifiers["Bladeswarm"], "Bladeswarm", [])
