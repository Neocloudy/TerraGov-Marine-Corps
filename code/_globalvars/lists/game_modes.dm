///List of all faction_stats datums, by faction
GLOBAL_LIST_EMPTY(faction_stats_datums)

///jobs by faction, ranked by seniority
GLOBAL_LIST_INIT(ranked_jobs_by_faction, list(
	FACTION_TERRAGOV = list(CAPTAIN, FIELD_COMMANDER, STAFF_OFFICER, SQUAD_LEADER),
	FACTION_SOM = list(SOM_COMMANDER, SOM_FIELD_COMMANDER, SOM_STAFF_OFFICER, SOM_SQUAD_LEADER, SOM_SQUAD_VETERAN),
))

///All jobs used in campaign
GLOBAL_LIST_INIT(campaign_jobs, list(
	SQUAD_MARINE,
	SQUAD_ENGINEER,
	SQUAD_CORPSMAN,
	SQUAD_SMARTGUNNER,
	SQUAD_LEADER,
	FIELD_COMMANDER,
	STAFF_OFFICER,
	CAPTAIN,
	SOM_SQUAD_MARINE,
	SOM_SQUAD_ENGINEER,
	SOM_SQUAD_CORPSMAN,
	SOM_SQUAD_VETERAN,
	SOM_SQUAD_LEADER,
	SOM_FIELD_COMMANDER,
	SOM_STAFF_OFFICER,
	SOM_COMMANDER,
))
