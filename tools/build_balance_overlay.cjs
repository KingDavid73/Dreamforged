// Measurement-only overlay: expose existing closures, never alter the installation.
const fs=require('fs'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'..');
const dir=path.join(root,'tests','balance-kernel-profile','overlay','scripts','ashenloot');fs.mkdirSync(dir,{recursive:true});
let source=fs.readFileSync(path.join(root,'scripts','ashenloot','global.lua'),'utf8');
const chance=source.match(/local ordinaryChance=([^\r\n]+)/)[1];
const death=source.slice(source.indexOf('local function death(actor)'));
const budgetRng=death.match(/local rng=([^\r\n]+)/)[1].replaceAll('actor.id','seed');
const gateRoll=death.match(/if rank==0 and (.+)>ordinaryChance then/)[1].replaceAll('actor.id','seed');
const helper=`measurementPlan=function(actor,rank,seed,bank)
    if not Delve.rewardEligible(actor) then return {eligible=false,tiers={}} end
    state.rewardDirector={bank=bank,hunger=0,kills=0,sprees=0}
    local rng=${budgetRng}
    local spend,d=rewardDirectorBudget(actor,rank,rng)
    local ordinaryChance=${chance}
    if rank==0 and ${gateRoll}>ordinaryChance then return {eligible=true,tiers={}} end
    local tiers=R.lootBudgetPlan(rng,rank,enemyLootBudget(actor,rank)+spend,mythicChance())
    return {eligible=true,tiers=tiers,baseBudget=enemyLootBudget(actor,rank),spend=spend}
end,measurementBudget=enemyLootBudget,`;
const anchor='test = {giveLoot = giveLoot,';assert(source.includes(anchor));source=source.replace(anchor,'test = {'+helper+'giveLoot = giveLoot,');
fs.writeFileSync(path.join(dir,'global.lua'),source);
console.log('Generated ignored measurement overlay; ordinary gate extracted from current source.');
