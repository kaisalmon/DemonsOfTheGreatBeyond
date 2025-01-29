const tsv = `id	name	type	cost	atk	def	abilities	type abilities	Opponent uses	upside
1	bones	ghost	1	1	2		cannot be blocked by beasts or by unpossessed objects. possess allied objects on row	2	0
2	goblin	beast	6	3	5	summon goblin in every row	cannot block ghosts	1	1
3	demon	beast	1	1	5		cannot block ghosts	0	0
4	spirit	ghost	2	1	5		cannot be blocked by beasts or by unpossessed objects. possess allied objects on row	3	0
5	blade	object	2	3	4		cannot block ghosts or attack if unpossessed.	2	0
6	orb	object	2	2	6	draw a card	cannot block ghosts or attack if unpossessed.	2	1
7	golem	object	3	3	12		cannot block ghosts or attack if unpossessed.	3	0
8	imp	beast	1	2	3		cannot block ghosts	2	0
9	bat	beast	3	3	5		cannot block ghosts	2	0
10	wil'o	ghost	4	3	8		cannot be blocked by beasts or by unpossessed objects. possess allied objects on row	1	0
11	furniture	object	0	1	6		cannot block ghosts or attack if unpossessed.	2	0
12	geist	ghost	5	3	10		cannot be blocked by beasts or by unpossessed objects. possess allied objects on row	1	0
13	snake	beast	2	2	2	hits to opponent deal double damage	cannot block ghosts	3	1
14	shroom	elemental	2	1	6		-	1	0
15	lich	ghost	6	3	14		cannot be blocked by beasts or by unpossessed objects. possess allied objects on row	1	0
16	slime	beast	2	1	8		cannot block ghosts	1	0
17	blinky	ghost	3	1	8		cannot be blocked by beasts or by unpossessed objects. possess allied objects on row	3	0
18	swarm	beast	1	2	2	50% chance to draw swarm	cannot block ghosts	1	1
19	jelpi	beast	3	1	8	heal 4	cannot block ghosts	2	1
20	wand	object	5	1	8	summon abilities trigger twice	cannot block ghosts or attack if unpossessed.	3	1
21	gorgon	beast	6	3	6	turn foes to stone	cannot block ghosts	2	1
22	candle	object	2	2	2	+1 mana	cannot block ghosts or attack if unpossessed.	3	1
23	zap	elemental	4	3	1	clear row	-	1	1
24	cactus	elemental	3	1	8	deal 3 damage to opponent	-	1	1
25	gargoyle	elemental	4	3	14	costs 5 life	-	1	-1
26	flame	elemental	4	3	3	2 damage to all foes	-	1	1
27	relic	object	3	1	5	kill all ghosts	cannot block ghosts or attack if unpossessed.	1	1
28	toad	beast	2	1	4	draw a card	cannot block ghosts	2	1
29	smog	elemental	3	3	1	can't block	-	1	-1
30	bug	beast	1	2	1	can't block beasts or ghosts	cannot block ghosts	1	-1
31	gnome	beast	4	1	1	discard all cards, draw 5	cannot block ghosts	0	1
32	skelly	ghost	4	2	7	summon bones	cannot be blocked by beasts or by unpossessed objects. possess allied objects on row	1	1
33	reaper	ghost	5	3	7	kill all injured	cannot be blocked by beasts or by unpossessed objects. possess allied objects on row	1	1
34	dragon	beast	6	3	10	summon flame	cannot block ghosts	2	1
35	mimic	beast	3	3	19	can't attack unless hurt	cannot block ghosts	1	-1
36	phish	beast	3	1	6	steal a card	cannot block ghosts	0	1
37	storm	elemental	4	2	8	elemental's summon abilities trigger twice	-	1	1
38	magnet	object	4	1	4	draw an object from your deck	cannot block ghosts or attack if unpossessed.	1	1
39	nomicon	object	4	1	4	draw an ghost from your deck	cannot block ghosts or attack if unpossessed.	0	1
40	devil	beast	6	3	6	draw an 5✽+ card from your deck	cannot block ghosts	1	1
41	cheese	object	2	1	1	draw up to 3 1✽ cards from your deck	cannot block ghosts or attack if unpossessed.	0	1
42	sapling	elemental	3	0	3	heal all allies	-	0	1
43	portal	elemental	3	0	8	each void you summon deals 2 damage to opponent	-	1	1
44	cultist	beast	5	3	6	draw each time you summon a void	cannot block ghosts	1	1
45	octopus	beast	2	2	6	summon tentacle either side	cannot block ghosts		1
46	raven	beast	4	2	2	draw a ghost and an object from your deck	cannot block ghosts		1`

const cards = tsv.split('\n').slice(1).map(line => {
    const [id,name,type,cost,atk,def,abilities,_typeAbilities,_opponentUses,upside] = line.split('\t')
    return {id, name, type, cost: +cost, atk: +atk, def: +def, upside: +upside, abilities}
})

const compare = (a, b, good) => {
    if (a===b) return "equal"
    return good ? a > b ? "better" : "worse" : a < b ? "better" : "worse"
}

const compareTypes = (a, b) => {
    if (a === b) return "equal"
    const order = ["ghost", "elemental", "beast", "object"]
    return order.indexOf(a) < order.indexOf(b) ? "better" : "worse"
}

const compareUpside = (a, b) => {
    if(a===0 && b===0) return "equal"
    if(a===b) return "incomparable"
    if(a>b) return "better"
    return "worse"
}

const withoutAbilities = card => {
    const result = {...card}
    result.abilities = ""
    result.upside = 0
    return result
}

const compareCards = (a, b) => {
    const comparisons = [
        compare(a.cost, b.cost, false),
        compare(a.atk, b.atk, true),
        compare(a.def, b.def, true),
        compareTypes(a.type, b.type),
        compareUpside(a.upside, b.upside)
    ]
    if (comparisons.includes("incomparable")) return "incomparable"
    if (comparisons.every(c => c === "equal")) return "equal"
    //A card is better if is better or equal in all comparisons and better in at least one
    const betterOrEqual = comparisons.every(c => c === "better" || c === "equal")
    const betterInAtLeastOne = comparisons.some(c => c === "better")

    if (betterOrEqual && betterInAtLeastOne) return "better"

    //A card is worse if is worse or equal in all comparisons and worse in at least one
    const worseOrEqual = comparisons.every(c => c === "worse" || c === "equal")
    const worseInAtLeastOne = comparisons.some(c => c === "worse")

    if (worseOrEqual && worseInAtLeastOne) return "worse"

    return "incomparable"
}

for(const card of cards) {
    for(const other of cards) {
        if(card === other) continue
        const comp = compareCards(card, other)
        if(comp === "better") console.log(`${card.name} dominates ${other.name}`)
        if(comp === "equal" ) console.log(`${card.name} duplicates ${other.name}`)
        if (card.upside === other.upside && card.upside !== 0) {
            const cardWithoutAbilities = withoutAbilities(card)
            const otherWithoutAbilities = withoutAbilities(other)
            const compWithoutAbilities = compareCards(cardWithoutAbilities, otherWithoutAbilities)
            // if(compWithoutAbilities === "better") console.log(`${card.name}'s "${card.abilities}" should be worse than ${other.name}'s "${other.abilities}"`)
            if(compWithoutAbilities === "worse") console.log(`${card.name}'s "${card.abilities}" should be better than ${other.name}'s "${other.abilities}"`)
            // if(compWithoutAbilities === "equal") console.log(`${card.name}'s "${card.abilities}" should be equal to ${other.name}'s "${other.abilities}"`)
        }
    }
}