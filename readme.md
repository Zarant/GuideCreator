#GuideCreator
##Overview
This is an addon for Vanilla WoW (1.12) that assists in the creation of in-game leveling guides by auto generating a Guidelime text string every time you accept, turn in or complete quest objectives.

##Commands
`/guide editor` Opens the text editor where you can edit each indivdual step or copy the text generated so you can move it over to a proper text editor
`/guide delete GuideName` Delete the specified guide, erasing its contents from memory
`/guide list` Lists all guides saved in memory
`/guide npcnames` Show NPC names upon accepting or turning in a quest
`/guide goto` Generate a goto step at your current location
`/guide mapcoords n` Set n to -1 to disable map coordinates generation and use Guidelime's database instead, set it to 0 to only generate map coordinates upon quest accept/turn in or set it to 1 enable waypoint generation upon completing quest objectives
`/guide current GuideName` Sets the current working guide