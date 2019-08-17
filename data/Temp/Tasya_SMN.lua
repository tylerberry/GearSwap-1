-------------------------------------------------------------------------------------------------------------------
-- Setup functions for this job.  Generally should not be modified.
-------------------------------------------------------------------------------------------------------------------

-- Also, you'll need the Shortcuts addon to handle the auto-targetting of the custom pact commands.

--[[
    Custom commands:
    
    gs c petweather
        Automatically casts the storm appropriate for the current avatar, if possible.
    
    gs c siphon
        Automatically run the process to: dismiss the current avatar; cast appropriate
        weather; summon the appropriate spirit; Elemental Siphon; release the spirit;
        and re-summon the avatar.
        
        Will not cast weather you do not have access to.
        Will not re-summon the avatar if one was not out in the first place.
        Will not release the spirit if it was out before the command was issued.
        
    gs c pact [PactType]
        Attempts to use the indicated pact type for the current avatar.
        PactType can be one of:
            cure
            curaga
            buffOffense
            buffDefense
            buffSpecial
            debuff1
            debuff2
            sleep
            nuke2
            nuke4
            bp70
            bp75 (merits and lvl 75-80 pacts)
            astralflow
--]]


-- Initialization function for this job file.
function get_sets()
    mote_include_version = 2

    -- Load and initialize the include file.
    include('Mote-Include.lua')
end

-- Setup vars that are user-independent.  state.Buff vars initialized here will automatically be tracked.
function job_setup()
    include('Tasya-Lib.lua')
    
	event_list = L{}
	event_list:append(windower.register_event('mpp change',tas_fucho_no_obi))

    state.Buff["Avatar's Favor"] = buffactive["Avatar's Favor"] or false
    state.Buff["Astral Conduit"] = buffactive["Astral Conduit"] or false

    spirits = S{"LightSpirit", "DarkSpirit", "FireSpirit", "EarthSpirit", "WaterSpirit", "AirSpirit", "IceSpirit", "ThunderSpirit"}
    avatars = S{"Carbuncle", "Fenrir", "Diabolos", "Ifrit", "Titan", "Leviathan", "Garuda", "Shiva", "Ramuh", "Odin", "Alexander", "Cait Sith"}

    magicalRagePacts = S{
        'Inferno','Earthen Fury','Tidal Wave','Aerial Blast','Diamond Dust','Judgment Bolt','Searing Light','Howling Moon','Ruinous Omen',
        'Fire II','Stone II','Water II','Aero II','Blizzard II','Thunder II',
        'Fire IV','Stone IV','Water IV','Aero IV','Blizzard IV','Thunder IV',
        'Thunderspark','Burning Strike','Meteorite','Nether Blast',
        'Holy Mist','Lunar Bay','Night Terror','Level ? Holy'}
        
    hybridRagePacts = S{'Flaming Crush'}
    
    tpRagePacts = S{'Meteor Strike','Heavenly Strike','Wind Blade','Geocrush','Thunderstorm','Grand Fall','Impact','Conflag Strike'}

    pacts = {}
    pacts.cure = {['Carbuncle']='Healing Ruby'}
    pacts.curaga = {['Carbuncle']='Healing Ruby II', ['Garuda']='Whispering Wind', ['Leviathan']='Spring Water'}
    pacts.buffoffense = {['Carbuncle']='Glittering Ruby', ['Ifrit']='Crimson Howl', ['Garuda']='Hastega', ['Ramuh']='Rolling Thunder',
        ['Fenrir']='Ecliptic Growl'}
    pacts.buffdefense = {['Carbuncle']='Shining Ruby', ['Shiva']='Frost Armor', ['Garuda']='Aerial Armor', ['Titan']='Earthen Ward',
        ['Ramuh']='Lightning Armor', ['Fenrir']='Ecliptic Howl', ['Diabolos']='Noctoshield', ['Cait Sith']='Reraise II'}
    pacts.buffspecial = {['Ifrit']='Inferno Howl', ['Garuda']='Fleet Wind', ['Titan']='Earthen Armor', ['Diabolos']='Dream Shroud',
        ['Carbuncle']='Soothing Ruby', ['Fenrir']='Heavenward Howl', ['Cait Sith']='Raise II'}
    pacts.debuff1 = {['Shiva']='Diamond Storm', ['Ramuh']='Shock Squall', ['Leviathan']='Tidal Roar', ['Fenrir']='Lunar Cry',
        ['Diabolos']='Pavor Nocturnus', ['Cait Sith']='Eerie Eye'}
    pacts.debuff2 = {['Shiva']='Sleepga', ['Leviathan']='Slowga', ['Fenrir']='Lunar Roar', ['Diabolos']='Somnolence'}
    pacts.sleep = {['Shiva']='Sleepga', ['Diabolos']='Nightmare', ['Cait Sith']='Mewing Lullaby'}
    pacts.nuke2 = {['Ifrit']='Fire II', ['Shiva']='Blizzard II', ['Garuda']='Aero II', ['Titan']='Stone II',
        ['Ramuh']='Thunder II', ['Leviathan']='Water II'}
    pacts.nuke4 = {['Ifrit']='Fire IV', ['Shiva']='Blizzard IV', ['Garuda']='Aero IV', ['Titan']='Stone IV',
        ['Ramuh']='Thunder IV', ['Leviathan']='Water IV'}
    pacts.bp70 = {['Ifrit']='Flaming Crush', ['Shiva']='Rush', ['Garuda']='Predator Claws', ['Titan']='Mountain Buster',
        ['Ramuh']='Chaotic Strike', ['Leviathan']='Spinning Dive', ['Carbuncle']='Meteorite', ['Fenrir']='Eclipse Bite',
        ['Diabolos']='Nether Blast',['Cait Sith']='Regal Scratch'}
    pacts.bp75 = {['Ifrit']='Meteor Strike', ['Shiva']='Heavenly Strike', ['Garuda']='Wind Blade', ['Titan']='Geocrush',
        ['Ramuh']='Thunderstorm', ['Leviathan']='Grand Fall', ['Carbuncle']='Holy Mist', ['Fenrir']='Lunar Bay',
        ['Diabolos']='Night Terror', ['Cait Sith']='Level ? Holy'}
    pacts.bp99 = {}
    pacts.astralflow = {['Ifrit']='Inferno', ['Shiva']='Diamond Dust', ['Garuda']='Aerial Blast', ['Titan']='Earthen Fury',
        ['Ramuh']='Judgment Bolt', ['Leviathan']='Tidal Wave', ['Carbuncle']='Searing Light', ['Fenrir']='Howling Moon',
        ['Diabolos']='Ruinous Omen', ['Cait Sith']="Altana's Favor"}

    -- Wards table for creating custom timers   
    wards = {}
    -- Base duration for ward pacts.4
    wards.durations = {
        ['Crimson Howl'] = 60, ['Earthen Armor'] = 60, ['Inferno Howl'] = 60, ['Heavenward Howl'] = 60,
        ['Rolling Thunder'] = 120, ['Fleet Wind'] = 120,
        ['Shining Ruby'] = 180, ['Frost Armor'] = 180, ['Lightning Armor'] = 180, ['Ecliptic Growl'] = 180,
        ['Glittering Ruby'] = 180, ['Hastega'] = 180, ['Noctoshield'] = 180, ['Ecliptic Howl'] = 180,
        ['Dream Shroud'] = 180,
        ['Reraise II'] = 3600
    }
    -- Icons to use when creating the custom timer.
    wards.icons = {
        ['Earthen Armor']   = 'spells/00299.png', -- 00299 for Titan
        ['Shining Ruby']    = 'spells/00043.png', -- 00043 for Protect
        ['Dream Shroud']    = 'spells/00304.png', -- 00304 for Diabolos
        ['Noctoshield']     = 'spells/00106.png', -- 00106 for Phalanx
        ['Inferno Howl']    = 'spells/00298.png', -- 00298 for Ifrit
        ['Hastega']         = 'spells/00358.png', -- 00358 for Hastega
        ['Rolling Thunder'] = 'spells/00104.png', -- 00358 for Enthunder
        ['Frost Armor']     = 'spells/00250.png', -- 00250 for Ice Spikes
        ['Lightning Armor'] = 'spells/00251.png', -- 00251 for Shock Spikes
        ['Reraise II']      = 'spells/00135.png', -- 00135 for Reraise
        ['Fleet Wind']      = 'abilities/00074.png', -- 
    }
    -- Flags for code to get around the issue of slow skill updates.
    wards.flag = false
    wards.spell = ''
end

-------------------------------------------------------------------------------------------------------------------
-- User setup functions for this job.  Recommend that these be overridden in a sidecar file.
-------------------------------------------------------------------------------------------------------------------

-- Setup vars that are user-dependent.  Can override this function in a sidecar file.
function user_setup()
    state.OffenseMode:options('None', 'Normal', 'Acc')
    state.CastingMode:options('Normal', 'Resistant')
    
    gear.AlternateIdleBelt = "Slipor Sash"
    
    select_default_macro_book()
end

function user_unload()
    event_list:map(windower.unregister_event)
    event_list:clear()
end

-- Define sets and vars used by this job file.
function init_gear_sets()

    --==================================--
	-- Augmented gear and base sets
    --==================================--

    include('Tasya-Gear.lua')
    tas_shared_augmented_gear()
    
    gear.Espiritus = {}
    gear.Espiritus.B = {name="Espiritus", augments={'Summoning magic skill +15','Pet: Mag. Acc.+30','Pet: Damage taken -4%'}}

    gear.ConveyanceCape = {}
    gear.ConveyanceCape.Delay = {name="Conveyance Cape", augments={'Blood Pact ab. del. II -3'}}

    sets.MaxSummoningSkill = {
        main=gear.Espiritus.B,sub="Vox Grip",ammo="Sancus Sachet +1",
        head="Convoker's Horn +1",neck="Incanter's Torque",ear1="Gifted Earring",ear2="Summoning Earring",
        body="Beckoner's Doublet +1",hands="Lamassu Mitts +1",ring1="Evoker's Ring",ring2="Stikini Ring +1",
        back=gear.ConveyanceCape.Delay,waist="Lucidity Sash",legs="Beckoner's Spats +1",feet="Beckoner's Pigaches +1"} -- feet="Marduk's Crackows +1"
    
    --==================================--
	-- Idle
    --==================================--

    sets.idle = {
        main="Contemplator +1",sub="Oneiros Grip",ammo="Sancus Sachet +1",
        head="Convoker's Horn +1",neck="Bathy Choker +1",ear1="Infused Earring",ear2="Dawn Earring",
        body=gear.ApogeeDalmaticaPlus1.A,hands="Asteria Mitts +1",ring1="Stikini Ring +1",ring2="Stikini Ring +1",
        back="Kumbira Cape",waist=gear.IdleBelt,legs="Assiduity Pants +1",feet="Crier's Gaiters"}

    --------------------------------------
	-- Perpetuation
    --------------------------------------
        
    -- perp costs:
    -- spirits: 7
    -- carby: 11 (5 with mitts)
    -- fenrir: 13
    -- others: 15
    -- avatar's favor: -4/tick
    
    -- Max useful -perp gear is 1 less than the perp cost (can't be reduced below 1)
    -- Aim for -14 perp, and refresh in other slots.
    
    -- -perp gear:
    -- Gridarvor: -5
    -- Hagondes Coat +1: -59
    -- Evoker's Ring: -1
	-- Assiduity Pants +1: -3
    -- Beckoner's Pigaches +1: -7
    -- Apogee Pumps: -8
    -- Apogee Pumps +1: -9
    -- total: -18
    
    -- Can make due without either the head or the body, and use +refresh items in those slots.
    
    sets.idle.Avatar = {
        main="Gridarvor",sub="Oneiros Grip",ammo="Sancus Sachet +1",
        head="Convoker's Horn +1",neck="Caller's Pendant",ear1="Infused Earring",ear2="Dawn Earring",
        body=gear.ApogeeDalmaticaPlus1.A,hands="Asteria Mitts +1",ring1="Evoker's Ring",ring2="Stikini Ring +1",
        back="Mecistopins Mantle",waist=gear.IdleBelt,legs="Assiduity Pants +1",feet=gear.ApogeePumpsPlus1.A}

    sets.idle.Spirit = {
        main="Gridarvor",sub="Oneiros Grip",ammo="Sancus Sachet +1",
        head="Convoker's Horn +1",neck="Bathy Choker +1",ear1="Infused Earring",ear2="Dawn Earring",
        body=gear.ApogeeDalmaticaPlus1.A,hands="Asteria Mitts +1",ring1="Evoker's Ring",ring2="Stikini Ring +1",
        back="Moonlight Cape",waist=gear.IdleBelt,legs="Glyphic Spats +1",feet="Serpentes Sabots"}

    sets.idle.Town = {
        main="Contemplator +1",sub="Oneiros Grip",ammo="Sancus Sachet +1",
        head="Convoker's Horn +1",neck="Bathy Choker +1",ear1="Infused Earring",ear2="Dawn Earring",
        body=gear.ApogeeDalmaticaPlus1.A,hands="Asteria Mitts +1",ring1="Stikini Ring +1",ring2="Stikini Ring +1",
        back="Kumbira Cape",waist=gear.IdleBelt,legs="Assiduity Pants +1",feet="Serpentes Sabots"}

    -- Favor uses Beckoner's Horn for refresh
    sets.idle.Avatar.Favor = {head="Beckoner's Horn +1"}
    --sets.idle.Avatar.Melee = {hands="Regimen Mittens",back="Samanisi Cape",waist="Kuku Stone",legs="Convoker's Spats +1"}
        
    sets.perp = {}
    
    -- Day and weather sets with Beckoner's Bracers aren't really worth using anymore given that Asteria Mitts +1 exist.
    
    --sets.perp.Day = {body="Hagondes Coat +1",hands="Beckoner's Bracers +1"}
    --sets.perp.Weather = {neck="Caller's Pendant",body="Hagondes Coat +1",hands="Beckoner's Bracers +1"}
    
    -- Carby: Asteria Mitts make Carbuncle's base perpetuation cost 5. Add Assiduity Pants +1 and Evoker's ring = 1/tick perp.
    
    sets.perp.Carbuncle = {
        main="Bolelabunga",sub="Genbu's Shield",
        head="Convoker's Horn +1",
        body=gear.ApogeeDalmaticaPlus1.A,hands="Asteria Mitts +1",ring1="Evoker's Ring",
        legs="Assiduity Pants +1",feet="Beckoner's Pigaches +1"}
        
    sets.perp['Cait Sith'] = {hands="Lamassu Mitts +1"}
    
    sets.perp.Alexander = sets.MaxSummoningSkill
    
	--==================================--
	-- Defense
    --==================================--
    
    -- Caps PDT, MDT with Shell V, -16 perpetuation cost, and lots of refresh.
    sets.defense.PDT = {
        main="Terra's Staff",sub="Oneiros Grip",ammo="Sancus Sachet +1",
        head="Beckoner's Horn +1",neck="Loricate Torque +1",ear1="Handler's Earring +1",ear2="Handler's Earring",
        body="Hagondes Coat +1",hands="Asteria Mitts +1",ring1="Defending Ring",ring2=gear.DarkRing.PDT,
        back="Moonlight Cape",waist="Isa Belt",legs="Assiduity Pants +1",feet=gear.ApogeePumpsPlus1.A}

    sets.defense.MDT = {
        main="Terra's Staff",sub="Oneiros Grip",ammo="Sancus Sachet +1",
        head="Hagondes Hat +1",neck="Warder's Charm +1",ear1="Gifted Earring",ear2="Loquacious Earring",
        body="Hagondes Coat +1",hands="Hagondes Cuffs +1",ring1="Defending Ring",ring2="Shadow Ring",
        back="Moonlight Cape",waist="Isa Belt",legs="Hagondes Pants +1",feet="Hagondes Sabots +1"}
    
	--==================================--
	-- Resting
    --==================================--
    
    sets.resting = {
        main="Contemplator +1",sub="Oneiros Grip",ammo="Sancus Sachet +1",
        head="Beckoner's Horn +1",neck="Eidolon Pendant +1",ear1="Gifted Earring",ear2="Loquacious Earring",
        body=gear.ApogeeDalmaticaPlus1.A,hands="Asteria Mitts +1",ring1="Stikini Ring +1",ring2="Stikini Ring +1",
        back="Kumbira Cape",waist=gear.IdleBelt,legs="Assiduity Pants +1",feet="Chelona Boots +1"}
	
	--==================================--
	-- Engaged
    --==================================--
    
    -- Normal melee group
    sets.engaged = {
        ammo="Sancus Sachet +1",
        head=gear.TelchineCap.DA,neck="Asperity Necklace",ear1="Brutal Earring",ear2="Cessance Earring",
        body="Onca Suit",hands=empty,ring1="Rajas Ring",ring2="Petrov Ring",
        back="Aurist's Cape +1",waist="Windbuffet Belt +1",legs=empty,feet=empty}

	--==================================--
	-- Job Abilities
    --==================================--
    
    -- Precast sets to enhance JAs
    sets.precast.JA['Astral Flow'] = {head="Glyphic Horn +1"}
    
    sets.precast.JA['Elemental Siphon'] = set_combine(sets.MaxSummoningSkill, {
        ammo="Esper Stone +1",back=gear.ConveyanceCape.Delay,feet="Beckoner's Pigaches +1"})

    sets.precast.JA['Mana Cede'] = {hands="Beckoner's Bracers +1"}

	--==================================--
	-- Blood Pact Delay
    --==================================--

    -- Pact delay reduction gear
    sets.precast.BloodPactWard = set_combine(sets.MaxSummoningSkill, {
        main=gear.Espiritus.B, sub="Oneiros Grip", ammo="Sancus Sachet +1",
        head="Beckoner's Horn +1", ear2="Evans Earring",
        body=gear.ApogeeDalmaticaPlus1.A, hands="Glyphic Bracers +1",
        legs="Glyphic Spats +1"})

    sets.precast.BloodPactRage = sets.precast.BloodPactWard

	--==================================--
	-- Weaponskills
    --==================================--
    
    sets.precast.WS = {
        head="Alhazen Hat +1",neck="Asperity Necklace",ear1="Brutal Earring",ear2="Cessance Earring",
        body="Onca Suit",hands=empty,ring1="Rajas Ring",ring2="Petrov Ring",
        back="Aurist's Cape +1",waist="Windbuffet Belt +1",legs=empty,feet=empty}

    -- Specific weaponskill sets.  Uses the base set if an appropriate WSMod version isn't found.
    sets.precast.WS['Myrkr'] = {
        head=gear.VanyaHood.D,ear1="Gifted Earring",ear2="Loquacious Earring",
        body="Beckoner's Doublet +1",hands="Beckoner's Bracers +1",ring1="Evoker's Ring",ring2="Stikini Ring +1",
        back="Aurist's Cape +1",waist="Fucho-no-Obi",legs="Assiduity Pants +1",feet="Chelona Boots +1"}

	--==================================--
	-- Fast Cast
    --==================================--
    
    sets.precast.FC = {
        head=gear.VanyaHood.D,neck="Orunmila's Torque",ear1="Enchanter Earring +1",ear2="Loquacious Earring",
        body="Anhur Robe",hands=gear.TelchineGloves.FCandEnh,ring1="Prolix Ring",ring2="Lebeche Ring",
        back="Perimede Cape",waist="Witful Belt",legs=gear.PsyclothLappas.D,feet="Regal Pumps +1"}

    sets.precast.FC['Enhancing Magic'] = set_combine(sets.precast.FC, {waist="Siegel Sash"})

	--==================================--
	-- Midcast
    --==================================--

    sets.midcast.FastRecast = {
        ammo="Hasty Pinion +1",
        head=gear.VanyaHood.D,neck="Orunmila's Torque",ear1="Enchanter Earring +1",ear2="Loquacious Earring",
        body=gear.HeliosJacket.MAB,hands=gear.TelchineGloves.FCandEnh,ring1="Prolix Ring",
        back="Swith Cape +1",waist="Witful Belt",legs=gear.PsyclothLappas.C,feet="Regal Pumps +1"}

	--==================================--
	-- Dark Magic
    --==================================--

    sets.midcast['Dark Magic'] = {
        main="Rubicundity",sub="Genbu's Shield",ammo="Pemphredo Tathlum",
        head="Befouled Crown",neck="Erra Pendant",ear1="Lifestorm Earring",ear2="Psystorm Earring",
        body=gear.VanyaRobe.C,hands="Hagondes Cuffs +1",ring1="Stikini Ring +1",ring2="Stikini Ring +1",
        back="Aurist's Cape +1",waist="Eschan Stone",legs=gear.PsyclothLappas.C,feet=gear.VanyaClogs.D}

    sets.midcast.Aspir = set_combine(sets.midcast['Dark Magic'], {
        head="Pixie Hairpin +1",ear1="Enchanter Earring +1",ear2="Hirudinea Earring",waist="Fucho-no-Obi"})
        
    sets.midcast.Drain = sets.midcast.Aspir
        
	--==================================--
	-- Elemental Magic
    --==================================--

    gear.default.ElementalCape = "Toro Cape"
    gear.default.ElementalObi = "Refoccilation Stone"
    
    sets.midcast['Elemental Magic'] = {
        main=gear.Grioavolr.MAB,sub="Enki Strap",ammo="Pemphredo Tathlum",
        head=gear.MerlinicHood.MAB,neck="Baetyl Pendant",ear1="Friomisi Earring",ear2="Novio Earring",
        body=gear.MerlinicJubbah.MAB,hands=gear.AmalricGagesPlus1.A,ring1="Shiva Ring +1",ring2="Shiva Ring +1",
        back=gear.ElementalCape,waist=gear.ElementalObi,legs=gear.MerlinicShalwar.MAB,feet=gear.MerlinicCrackows.MAB}

	--==================================--
	-- Enhancing Magic
    --==================================--

    sets.midcast.Stoneskin = {waist="Siegel Sash"}

	--==================================--
	-- Healing Magic
    --==================================--
    
    sets.midcast.Cure = {
        main="Tamaxchi",sub="Genbu's Shield",
        head=gear.VanyaHood.A,neck="Incanter's Torque",ear1="Mendicant's Earring",ear2="Loquacious Earring",
        body="Heka's Kalasiris",hands=gear.TelchineGloves.FCandEnh,ring1="Stikini Ring +1",ring2="Stikini Ring +1",
        back="Aurist's Cape +1",waist="Witful Belt",legs=gear.VanyaSlops.C,feet=gear.VanyaClogs.D}

	--==================================--
	-- Pet Blood Pacts
    --==================================--
    
    sets.midcast.Pet.BloodPactWard = set_combine(sets.MaxSummoningSkill, {
        head="Beckoner's Horn +1",
        body="Beckoner's Doublet +1",hands="Beckoner's Bracers +1",
        legs="Beckoner's Spats +1",feet="Beckoner's Pigaches +1"})

    sets.midcast.Pet.DebuffBloodPactWard = sets.MaxSummoningSkill
        
    sets.midcast.Pet.DebuffBloodPactWard.Acc = sets.midcast.Pet.DebuffBloodPactWard
    
    sets.midcast.Pet.PhysicalBloodPactRage = {
        main="Gridarvor",sub="Elan Strap +1",ammo="Sancus Sachet +1",
        head=gear.HeliosBand.PhysBP,neck="Empath Necklace",ear1="Kyrene's Earring",ear2="Lugalbanda Earring",
        body="Convoker's Doublet +2",hands=gear.MerlinicDastanas.PhysBP,ring1="Varar Ring +1",ring2="Varar Ring +1",
        back="Campestres's Cape",waist="Incarnation Sash",legs=gear.ApogeeSlacksPlus1.D,feet=gear.HeliosBoots.PhysBP}

    sets.midcast.Pet.PhysicalBloodPactRage.Acc = sets.midcast.Pet.PhysicalBloodPactRage

    sets.midcast.Pet.MagicalBloodPactRage = {
        main=gear.Grioavolr.MagicBP,sub="Elan Strap +1",ammo="Sancus Sachet +1",
        head=gear.ApogeeCrownPlus1.A,neck="Adad Amulet",ear1="Kyrene's Earring",ear2="Lugalbanda Earring",
        body=gear.ApogeeDalmaticaPlus1.A,hands=gear.MerlinicDastanas.MagicBP,ring1="Varar Ring +1",ring2="Varar Ring +1",
        back="Campestres's Cape",waist="Incarnation Sash",legs=gear.ApogeeSlacksPlus1.D,feet=gear.ApogeePumpsPlus1.A}

    sets.midcast.Pet.MagicalBloodPactRage.Acc = sets.midcast.Pet.MagicalBloodPactRage
    
    sets.midcast.Pet.HybridBloodPactRage = set_combine(sets.midcast.Pet.MagicalBloodPactRage, {
		body="Convoker's Doublet +2",
		back="Campestres's Cape"})
    sets.midcast.Pet.HybridBloodPactRage.Acc = sets.midcast.Pet.MagicalBloodPactRage.Acc
    
    sets.midcast.Pet.TPMagicalBloodPactRage = set_combine(sets.midcast.Pet.MagicalBloodPactRage, {legs="Enticer's Pants"})
    sets.midcast.Pet.TPMagicalBloodPactRage.Acc = sets.midcast.Pet.TPMagicalBloodPactRage
    
    -- Spirits cast magic spells, which can be identified in standard ways.
    
    sets.midcast.Pet.WhiteMagic = {legs="Glyphic Spats +1"}
    
    sets.midcast.Pet['Elemental Magic'] = set_combine(sets.midcast.Pet.MagicalBloodPactRage, {
        back="Campestres's Cape",legs="Glyphic Spats +1"})
    sets.midcast.Pet['Elemental Magic'].Resistant = sets.midcast.Pet['Elemental Magic']

	--==================================--
	-- Miscellaneous Sets
    --==================================--

    sets.Kiting = {feet="Crier's Gaiters"}
	
    --==================================--
	-- Organizer Items
    --==================================--
    
    organizer_items = tas_permissive_set_combine(tas_global_organizer_items, {
        echo_drops="Echo Drops"})
end

-------------------------------------------------------------------------------------------------------------------
-- Job-specific hooks for standard casting events.
-------------------------------------------------------------------------------------------------------------------

-- Set eventArgs.handled to true if we don't want any automatic gear equipping to be done.
-- Set eventArgs.useMidcastGear to true if we want midcast gear equipped on precast.
function job_precast(spell, action, spellMap, eventArgs)
    if state.Buff['Astral Conduit'] and pet_midaction() then
        eventArgs.handled = true
    end
end

function job_midcast(spell, action, spellMap, eventArgs)
    if state.Buff['Astral Conduit'] and pet_midaction() then
        eventArgs.handled = true
    end
end

-- Runs when pet completes an action.
function job_pet_aftercast(spell, action, spellMap, eventArgs)
    if not spell.interrupted and spell.type == 'BloodPactWard' and spellMap ~= 'DebuffBloodPactWard' then
        wards.flag = true
        wards.spell = spell.english
        send_command('wait 4; gs c reset_ward_flag')
    end
end

-------------------------------------------------------------------------------------------------------------------
-- Job-specific hooks for non-casting events.
-------------------------------------------------------------------------------------------------------------------

-- Called when a player gains or loses a buff.
-- buff == buff gained or lost
-- gain == true if the buff was gained, false if it was lost.
function job_buff_change(buff, gain)
    if state.Buff[buff] ~= nil then
        handle_equipping_gear(player.status)
    elseif storms:contains(buff) then
        handle_equipping_gear(player.status)
    end
end


-- Called when the player's pet's status changes.
-- This is also called after pet_change after a pet is released.  Check for pet validity.
function job_pet_status_change(newStatus, oldStatus, eventArgs)
    if pet.isvalid and not midaction() and not pet_midaction() and (newStatus == 'Engaged' or oldStatus == 'Engaged') then
        handle_equipping_gear(player.status, newStatus)
    end
end


-- Called when a player gains or loses a pet.
-- pet == pet structure
-- gain == true if the pet was gained, false if it was lost.
function job_pet_change(petparam, gain)
    classes.CustomIdleGroups:clear()
    if gain then
        if avatars:contains(pet.name) then
            classes.CustomIdleGroups:append('Avatar')
        elseif spirits:contains(pet.name) then
            classes.CustomIdleGroups:append('Spirit')
        end
    else
        select_default_macro_book('reset')
    end
end

-------------------------------------------------------------------------------------------------------------------
-- User code that supplements standard library decisions.
-------------------------------------------------------------------------------------------------------------------

-- Custom spell mapping.
function job_get_spell_map(spell)
    if spell.type == 'BloodPactRage' then
        if magicalRagePacts:contains(spell.english) then
            return 'MagicalBloodPactRage'
        elseif hybridRagePacts:contains(spell.english) then
            return 'HybridBloodPactRage'
        elseif tpRagePacts:contains(spell.english) then
            return 'TPMagicalBloodPactRage'
        else
            return 'PhysicalBloodPactRage'
        end
    elseif spell.type == 'BloodPactWard' and spell.target.type == 'MONSTER' then
        return 'DebuffBloodPactWard'
    end
end

-- Modify the default idle set after it was constructed.
function customize_idle_set(idleSet)
    if pet.isvalid then
        if pet.element == world.day_element then
            idleSet = set_combine(idleSet, sets.perp.Day)
        end
        if pet.element == world.weather_element then
            idleSet = set_combine(idleSet, sets.perp.Weather)
        end
        if sets.perp[pet.name] then
            idleSet = set_combine(idleSet, sets.perp[pet.name])
        end
        if state.Buff["Avatar's Favor"] and avatars:contains(pet.name) then
            idleSet = set_combine(idleSet, sets.idle.Avatar.Favor)
        end
        if pet.status == 'Engaged' then
            idleSet = set_combine(idleSet, sets.idle.Avatar.Melee)
        end
    end
    
    return idleSet
end

-- Called by the 'update' self-command, for common needs.
-- Set eventArgs.handled to true if we don't want automatic equipping of gear.
function job_update(cmdParams, eventArgs)
    classes.CustomIdleGroups:clear()
    if pet.isvalid then
        if avatars:contains(pet.name) then
            classes.CustomIdleGroups:append('Avatar')
        elseif spirits:contains(pet.name) then
            classes.CustomIdleGroups:append('Spirit')
        end
    end
end

-- Set eventArgs.handled to true if we don't want the automatic display to be run.
function display_current_job_state(eventArgs)

end


-------------------------------------------------------------------------------------------------------------------
-- User self-commands.
-------------------------------------------------------------------------------------------------------------------

-- Called for custom player commands.
function job_self_command(cmdParams, eventArgs)
    if cmdParams[1]:lower() == 'petweather' then
        handle_petweather()
        eventArgs.handled = true
    elseif cmdParams[1]:lower() == 'siphon' then
        handle_siphoning()
        eventArgs.handled = true
    elseif cmdParams[1]:lower() == 'pact' then
        handle_pacts(cmdParams)
        eventArgs.handled = true
    elseif cmdParams[1] == 'reset_ward_flag' then
        wards.flag = false
        wards.spell = ''
        eventArgs.handled = true
    end
end


-------------------------------------------------------------------------------------------------------------------
-- Utility functions specific to this job.
-------------------------------------------------------------------------------------------------------------------

-- Cast the appopriate storm for the currently summoned avatar, if possible.
function handle_petweather()
    if player.sub_job ~= 'SCH' then
        add_to_chat(122, "You can not cast storm spells")
        return
    end
        
    if not pet.isvalid then
        add_to_chat(122, "You do not have an active avatar.")
        return
    end
    
    local element = pet.element
    if element == 'Thunder' then
        element = 'Lightning'
    end
    
    if S{'Light','Dark','Lightning'}:contains(element) then
        add_to_chat(122, 'You do not have access to '..elements.storm_of[element]..'.')
        return
    end 
    
    local storm = elements.storm_of[element]
    
    if storm then
        send_command('@input /ma "'..elements.storm_of[element]..'" <me>')
    else
        add_to_chat(123, 'Error: Unknown element ('..tostring(element)..')')
    end
end


-- Custom uber-handling of Elemental Siphon
function handle_siphoning()
    if areas.Cities:contains(world.area) then
        add_to_chat(122, 'Cannot use Elemental Siphon in a city area.')
        return
    end

    local siphonElement
    local stormElementToUse
    local releasedAvatar
    local dontRelease
    
    -- If we already have a spirit out, just use that.
    if pet.isvalid and spirits:contains(pet.name) then
        siphonElement = pet.element
        dontRelease = true
        -- If current weather doesn't match the spirit, but the spirit matches the day, try to cast the storm.
        if player.sub_job == 'SCH' and pet.element == world.day_element and pet.element ~= world.weather_element then
            if not S{'Light','Dark','Lightning'}:contains(pet.element) then
                stormElementToUse = pet.element
            end
        end
    -- If we're subbing /sch, there are some conditions where we want to make sure specific weather is up.
    -- If current (single) weather is opposed by the current day, we want to change the weather to match
    -- the current day, if possible.
    elseif player.sub_job == 'SCH' and world.weather_element ~= 'None' then
        -- We can override single-intensity weather; leave double weather alone, since even if
        -- it's partially countered by the day, it's not worth changing.
        if get_weather_intensity() == 1 then
            -- If current weather is weak to the current day, it cancels the benefits for
            -- siphon.  Change it to the day's weather if possible (+0 to +20%), or any non-weak
            -- weather if not.
            -- If the current weather matches the current avatar's element (being used to reduce
            -- perpetuation), don't change it; just accept the penalty on Siphon.
            if world.weather_element == elements.weak_to[world.day_element] and
                (not pet.isvalid or world.weather_element ~= pet.element) then
                -- We can't cast lightning/dark/light weather, so use a neutral element
                if S{'Light','Dark','Lightning'}:contains(world.day_element) then
                    stormElementToUse = 'Wind'
                else
                    stormElementToUse = world.day_element
                end
            end
        end
    end
    
    -- If we decided to use a storm, set that as the spirit element to cast.
    if stormElementToUse then
        siphonElement = stormElementToUse
    elseif world.weather_element ~= 'None' and (get_weather_intensity() == 2 or world.weather_element ~= elements.weak_to[world.day_element]) then
        siphonElement = world.weather_element
    else
        siphonElement = world.day_element
    end
    
    local command = ''
    local releaseWait = 0
    
    if pet.isvalid and avatars:contains(pet.name) then
        command = command..'input /pet "Release" <me>;wait 1.1;'
        releasedAvatar = pet.name
        releaseWait = 10
    end
    
    if stormElementToUse then
        command = command..'input /ma "'..elements.storm_of[stormElementToUse]..'" <me>;wait 4;'
        releaseWait = releaseWait - 4
    end
    
    if not (pet.isvalid and spirits:contains(pet.name)) then
        command = command..'input /ma "'..elements.spirit_of[siphonElement]..'" <me>;wait 4;'
        releaseWait = releaseWait - 4
    end
    
    command = command..'input /ja "Elemental Siphon" <me>;'
    releaseWait = releaseWait - 1
    releaseWait = releaseWait + 0.1
    
    if not dontRelease then
        if releaseWait > 0 then
            command = command..'wait '..tostring(releaseWait)..';'
        else
            command = command..'wait 1.1;'
        end
        
        command = command..'input /pet "Release" <me>;'
    end
    
    if releasedAvatar then
        command = command..'wait 1.1;input /ma "'..releasedAvatar..'" <me>'
    end
    
    send_command(command)
end


-- Handles executing blood pacts in a generic, avatar-agnostic way.
-- cmdParams is the split of the self-command.
-- gs c [pact] [pacttype]
function handle_pacts(cmdParams)
    if areas.Cities:contains(world.area) then
        add_to_chat(122, 'You cannot use pacts in town.')
        return
    end

    if not pet.isvalid then
        add_to_chat(122,'No avatar currently available. Returning to default macro set.')
        select_default_macro_book('reset')
        return
    end

    if spirits:contains(pet.name) then
        add_to_chat(122,'Cannot use pacts with spirits.')
        return
    end

    if not cmdParams[2] then
        add_to_chat(123,'No pact type given.')
        return
    end
    
    local pact = cmdParams[2]:lower()
    
    if not pacts[pact] then
        add_to_chat(123,'Unknown pact type: '..tostring(pact))
        return
    end
    
    if pacts[pact][pet.name] then
        if pact == 'astralflow' and not buffactive['astral flow'] then
            add_to_chat(122,'Cannot use Astral Flow pacts at this time.')
            return
        end
        
        -- Leave out target; let Shortcuts auto-determine it.
        send_command('@input /pet "'..pacts[pact][pet.name]..'"')
    else
        add_to_chat(122,pet.name..' does not have a pact of type ['..pact..'].')
    end
end


-- Event handler for updates to player skill, since we can't rely on skill being
-- correct at pet_aftercast for the creation of custom timers.
windower.raw_register_event('incoming chunk',
    function (id)
        if id == 0x62 then
            if wards.flag then
                create_pact_timer(wards.spell)
                wards.flag = false
                wards.spell = ''
            end
        end
    end)

-- Function to create custom timers using the Timers addon.  Calculates ward duration
-- based on player skill and base pact duration (defined in job_setup).
function create_pact_timer(spell_name)
    -- Create custom timers for ward pacts.
    if wards.durations[spell_name] then
        local ward_duration = wards.durations[spell_name]
        if ward_duration < 181 then
            local skill = player.skills.summoning_magic
            if skill > 300 then
                skill = skill - 300
                if skill > 200 then skill = 200 end
                ward_duration = ward_duration + skill
            end
        end
        
        local timer_cmd = 'timers c "'..spell_name..'" '..tostring(ward_duration)..' down'
        
        if wards.icons[spell_name] then
            timer_cmd = timer_cmd..' '..wards.icons[spell_name]
        end

        send_command(timer_cmd)
    end
end


-- Select default macro book on initial load or subjob change.
function select_default_macro_book(reset)
    if reset == 'reset' then
        -- lost pet, or tried to use pact when pet is gone
    end
    
    -- Default macro set/book
    set_macro_page(4, 16)
end