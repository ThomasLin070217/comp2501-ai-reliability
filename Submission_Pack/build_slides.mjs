// Layout only. Experimental values are read from the R-prepared JSON unchanged.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {pathToFileURL} from 'node:url';
const require=createRequire(import.meta.url);
const {Presentation,PresentationFile}=await import(pathToFileURL(require.resolve('@oai/artifact-tool')).href);
const root=process.cwd(), skill=process.env.SKILL_DIR, python=process.env.RUNTIME_PYTHON;
if(!skill||!python)throw Error('Set SKILL_DIR and RUNTIME_PYTHON to bundled runtime paths');
const {resolvePresentationFont,applyPresentationChartFont,finalizePresentation}=await import(pathToFileURL(path.join(skill,'container_tools/artifact_tool_utils.mjs')));
const font=resolvePresentationFont();
const d=JSON.parse(await fs.readFile('Submission_Pack/evidence/artifact_content.json','utf8'));
const v=JSON.parse(await fs.readFile('Submission_Pack/evidence/visualization_data.json','utf8'));
const build=path.join(root,'.submission-build','natural-crosscheck');await fs.mkdir(build,{recursive:true});
const p=Presentation.create({slideSize:{width:1280,height:720}});
const navy='#142C40',teal='#147E77',red='#C45F48',muted='#657586',bg='#FAFBFD';
function text(s,t,x,y,w,h,size=30,color=navy,bold=false){const b=s.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});b.text=t;b.text.style={typeface:font,fontSize:size,bold,color,autoFit:'none'};return b;}
function slide(title){const s=p.slides.add();s.background.fill=bg;text(s,title,66,42,1148,title.includes('\n')?140:95,44,navy,true);return s;}
function note(s,i){const j=d.order.indexOf(i);if(j<0)throw Error('Missing note mapping');s.speakerNotes.textFrame.setText(d.notes[j]);text(s,String(j+1),1160,665,60,40,18,muted);}
function table(s,values,top=165,height=330,widths=null,size=27){const n=values[0].length;const t=s.tables.add({rows:values.length,columns:n,left:72,top,width:1136,height,columnWidths:widths||Array(n).fill(1136/n),values});for(let r=0;r<values.length;r++)for(let c=0;c<n;c++){const cell=t.getCell(r,c);cell.fill=r===0?navy:(r%2?'#F0F4F7':'#FFFFFF');cell.text.style={typeface:font,fontSize:size,color:r===0?'#FFFFFF':navy,bold:r===0};}return t;}
function body(s,lines){lines.forEach((t,i)=>text(s,t,72,174+i*102,1120,83,30));}
function chart(s,rows,key,cats,fill,opts={}){
 const c=s.charts.add('bar',{position:{left:100,top:170,width:1060,height:360},categories:cats,series:[{name:key,values:rows.map(z=>z[key]),fill}],barOptions:{direction:'column',grouping:'clustered'},hasLegend:false,dataLabels:{showValue:true,position:'outEnd',textStyle:{fontSize:24}},xAxis:{textStyle:{fontSize:23}},yAxis:{minimumScale:0,numberFormatCode:'0',textStyle:{fontSize:22}},...opts});applyPresentationChartFont(c,{fontFamily:font});return c;
}
const fact=c=>d.factual.find(z=>z.condition===c);
const nr=domain=>d.natural.rates.filter(z=>z.domain===domain);
const nl=domain=>d.natural.comparison_labels.find(z=>z.domain===domain);
function rateBars(sl,rows,categories,key,left=88,width=1100,top=180,height=350){
 const palette=['#8B9BAE','#657586','#C45F48','#147E77'];
 const c=sl.charts.add('bar',{position:{left,top,width,height},categories,series:[{name:'Error rate',values:rows.map(z=>z[key]),valuesFormatCode:'0.00%',fill:red,points:rows.map((z,idx)=>({idx,fill:palette[idx]}))}],barOptions:{direction:'column',grouping:'clustered'},hasLegend:false,dataLabels:{showValue:true,position:'outEnd',textStyle:{fontSize:25,bold:true}},xAxis:{textStyle:{fontSize:23}},yAxis:{min:0,max:1,majorUnit:.25,numberFormatCode:'0%',textStyle:{fontSize:21}}});applyPresentationChartFont(c,{fontFamily:font});return c;
}
let s=slide('Can We Trust AI More\nAfter Cross-Checking?');
text(s,'COMP2501',72,275,1100,50,28,teal,true);
text(s,d.authors.join('  /  '),72,345,1100,60,34,navy,true);
text(s,'Natural cross-checking, misleading advice and structured verification',72,450,1090,90,30);
text(s,'Factual questions and mathematical reasoning  /  R analysis',72,572,1100,50,25,muted);note(s,0);
s=slide('The classroom question');body(s,[
 'Professor LUO RUIBANG asked who would completely trust AI.',
 'I raised my hand: I use multiple agents to cross-check answers.',
 'That confidence led to a question: does the extra check actually help?',
 'And what happens when the other model, or my own premise, is wrong?']);
text(s,"Paraphrased from LINYUNIAN’s recollection of the class",72,618,1120,38,22,muted);note(s,1);
s=slide('Three parts of one reliability question');
table(s,[['Module','Question','Evidence'],['A  Natural checking','Does another model add value?','49 questions / new follow-up'],['B  Misleading advice','Can a wrong suggestion spread?','120 factual questions'],['C  Structured checking','Can explicit checking reduce harm?','Matched advice comparisons']],165,325,[280,510,346],25);
text(s,'Facts and mathematics are analysed separately.',72,535,1120,50,30,teal,true);
text(s,'A is post hoc on previously studied questions. Original B/C endpoints are retained.',72,602,1120,65,24,muted);note(s,2);
s=slide('A  Natural cross-checking design');
table(s,[['Group','Information','Action'],['N0','Original question','Independent initial answer'],['N1','Question + own N0','Self-check'],['N2','Same N0 + another model’s natural answer','Peer-check'],['N3','Identical N2 peer material','Structured peer-check']],165,350,[150,590,396],25);
text(s,'Primary comparison: N2 versus N1',72,543,1120,50,31,teal,true);
text(s,'One receiving-model revision per branch. No assigned truth targets or search tools.',72,610,1120,60,24,muted);note(s,3);
s=slide('A  Natural checking: factual error');
rateBars(s,nr('facts'),['N0 Direct\nanswer','N1 Self\ncheck','N2 Peer\ncheck','N3 Structured\npeer check'],'error_rate');
text(s,nl('facts').text,72,552,1135,60,27,teal,true);
text(s,`Bars: ${nr('facts')[0].n} common units, peer − self = −3.96 pp. Primary pairs: n=${nl('facts').n}.`,72,613,1135,48,23,muted);note(s,4);
s=slide('A  Natural checking: mathematical error');
rateBars(s,nr('mathematics'),['N0 Direct\nanswer','N1 Self\ncheck','N2 Peer\ncheck','N3 Structured\npeer check'],'error_rate');
text(s,nl('mathematics').text,72,552,1135,56,27,teal,true);
text(s,`13 items, n=${nr('mathematics')[0].n}. Eight of ten N0 errors had correct reasoning endpoints.`,72,611,1135,55,23,muted);note(s,5);
s=slide('A  Which factual answers changed?');
table(s,d.natural.transition_table,195,290,[275,287,287,287],29);
text(s,'Rows: self-check N1  /  Columns: natural peer-check N2',72,144,1120,40,24,muted);
text(s,'Both helpful and harmful changes count.',72,533,1120,50,30,teal,true);
text(s,'These are paired parallel branches. An uncertain model can also be led into error.',72,602,1120,60,25,muted);note(s,6);
s=slide('B/C  Controlled advice and checking');
table(s,[['Group','Peer material','Follow-up'],['C0','None','Ordinary recheck'],['C1','Assigned wrong answer','Ordinary recheck'],['C2','Wrong answer + reason','Ordinary recheck'],['C3','Identical C2 material','Structured check'],['C4','Correct answer + reason','Ordinary recheck'],['C5','Identical C4 material','Structured check']],156,410,[170,590,376],25);
text(s,'120 factual questions; 719 complete units. Each branch shares the same initial answer.',72,603,1130,65,24,muted);note(s,7);
s=slide('B/C  Wrong input and structured checking');
text(s,'Misleading input',72,140,550,50,30,navy,true);
text(s,'Structured double-check',668,140,545,50,30,navy,true);
// Use explicit chart construction to retain per-category colors.
function cb(conditions,categories,left,width){const rr=conditions.map(c=>v.error_rates.find(z=>z.condition===c));const colors={C0:muted,C1:red,C2:red,C3:teal};const c=s.charts.add('bar',{position:{left,top:215,width,height:330},categories,series:[{name:'Error rate',values:rr.map(z=>z.rate),valuesFormatCode:'0.00%',fill:red,points:rr.map((z,idx)=>({idx,fill:colors[z.condition]}))}],barOptions:{direction:'column',grouping:'clustered'},hasLegend:false,dataLabels:{showValue:true,position:'outEnd',textStyle:{fontSize:25,bold:true}},xAxis:{textStyle:{fontSize:21}},yAxis:{min:0,max:1,majorUnit:.25,numberFormatCode:'0%',textStyle:{fontSize:21}}});applyPresentationChartFont(c,{fontFamily:font});}
cb(['C0','C1','C2'],['C0 Neutral\nrecheck','C1 Wrong\nanswer','C2 Wrong +\nreason'],58,562);
cb(['C2','C3'],['C2 Ordinary\nrecheck','C3 Structured\ncheck'],656,552);
text(s,'+18.78 / +6.40 percentage points vs C0',72,552,560,50,23,red,true);
text(s,'16.55 percentage points less error',676,552,530,50,23,teal,true);
text(s,'Error = wrong / (correct + wrong + abstain). Each group: 719.',72,608,1140,38,24,navy,true);
text(s,'Abstentions stay in the denominator. These all-unit comparisons are post hoc.',72,654,1100,32,21,muted);note(s,8);
s=slide('C  Most avoided errors became abstentions');
const ht=table(s,d.transition_table,190,292,[275,287,287,287],29);
for(let r=1;r<4;r++)for(let c=1;c<4;c++){const cell=ht.getCell(r,c);cell.fill=v.heat_colors[r-1][c-1];cell.text.style={typeface:font,fontSize:29,color:Number(d.transition_table[r][c])>180?'#FFFFFF':navy,bold:true};}
text(s,'Rows: C2  /  Columns: C3  /  All 719 paired units',72,140,1120,40,24,muted);
text(s,'144 wrong-to-abstain pairs; 5 wrong-to-correct',72,535,1120,52,30,teal,true);
text(s,'Reverse changes remain: 21 abstain-to-wrong and 9 correct-to-wrong.',72,602,1120,55,25,muted);note(s,9);
s=slide('C  Fewer useful corrections were accepted');
chart(s,['C4','C5'].map(fact),'incorrect_to_correct',['C4 Correct advice','C5 Structured'],teal);
text(s,'Successful corrections out of 322 initially wrong units',72,550,1120,40,27,teal,true);
text(s,'Difference: -9.63 pp   /   95% cluster interval [-14.38, -5.25]',72,607,1130,52,25,muted);note(s,10);
s=slide('Mathematical validity before calculation');body(s,[
 'An equilateral triangle has perimeter 30 cm and height 10 cm.',
 'Direct substitution gives area = 10 × 10 / 2 = 50.',
 'But side 10 forces height 5√3 ≈ 8.66. The conditions contradict.',
 '“Inconsistent” is a correct conclusion, not an abstention.']);note(s,11);
s=slide('What we count as an error');body(s,[
 'Error rate = wrong / (correct + wrong + explicit abstention).',
 'Correct answers and abstentions remain separate outcomes.',
 'We score final fields; an explanation can disagree with its answer.',
 'API failures and invalid formats are reported separately.']);note(s,12);
s=slide('A wrong date presented as verified');
text(s,'Notepad++ 7.8.8: official release date 28 June 2020',72,159,1120,45,29,teal,true);
table(s,[['Parallel branch','MiniMax response'],['C0 Neutral','Cannot confirm a date'],['C1 / C2 Wrong advice','29 June 2020 (wrong)'],['C3 Structured','Cannot verify the supplied claim']],220,255,[330,806],27);
text(s,'C1: “as confirmed by the official Notepad++ release notes”',72,510,1120,52,28);
text(s,'No search tool was available. A verification claim is not a retrieval record.',72,578,1120,70,25,muted);note(s,13);
s=slide('Evidence and limits');body(s,[
 'Selected date questions and four mathematical reasoning families.',
 'Natural checking increased Kimi’s factual error, while other models improved.',
 'R processing and targeted AI review; no independent human audit.',
 'Advice was labelled AI. Human trust and decisions were not measured.']);note(s,14);
s=slide('Can we trust AI more after checking?');body(s,[
 'Natural factual error benefit remains uncertain. Two arithmetic errors were repaired.',
 'Controlled wrong advice can raise the probability of a wrong answer.',
 'Structured checking can reduce wrong output by admitting uncertainty.',
 'Cross-checking provides no guarantee that the final answer is true.']);note(s,15);
s=slide('A proposed workflow for users');body(s,[
 'State which parts of your prompt are assumptions or unverified guesses.',
 'Let models answer independently before showing your preferred answer.',
 'Check conflicting claims against evidence; retain unresolved uncertainty.',
 'Use reliable sources or executable checks for consequential claims.']);
text(s,'External retrieval and calculators were not tested in this project.',72,622,1120,40,22,muted);note(s,16);
s=slide('References and contributions');
const refs=['Google SimpleQA Verified: factual question source','Huang et al. (ICLR 2024): limits of intrinsic self-correction','Dhuliawala et al. (ACL Findings 2024): Chain-of-Verification','Zhao et al. (EMNLP 2024): MathTrap','Mirzadeh et al. (ICLR 2025): GSM-Symbolic'];
refs.forEach((r,i)=>text(s,r,72,168+i*63,1120,53,27));
text(s,'LINYUNIAN and PAN ZHENGYU\nR processing and Codex assistance. Earlier Claude Code review used Kimi.',72,535,1120,98,25,muted);note(s,17);
const candidate=path.join(build,'candidate.pptx');await(await PresentationFile.exportPptx(p)).save(candidate);
for(let i=0;i<p.slides.items.length;i++){const png=await p.export({slide:p.slides.items[i],format:'png',scale:1});await fs.writeFile(path.join(build,`slide-${i+1}.png`),new Uint8Array(await png.arrayBuffer()));}
const final=path.resolve(root,process.env.OUTPUT_PPTX||'Submission_Pack/COMP2501_presentation.pptx');await fs.mkdir(path.dirname(final),{recursive:true});
const tables=[3,4,7,8,10,14];
await finalizePresentation({workspaceDir:root,candidatePath:candidate,finalPath:final,pythonExecutable:python,integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-heading-fit',...tables.flatMap(n=>['--require-native-table-slide',String(n)])],explicitTotalSlideCount:18,requiredNativeTableOwnerSlides:tables,requiredNativeChartOwnerSlides:[5,6,9,11],materializeLiteralChartWorkbooks:true,fontPolicy:{basis:'design',families:[font]},verifyArtifactToolImport:true,receiptPath:path.join(build,`validation-${Date.now()}.json`)});
console.log(`Created ${final}; font ${font}`);
