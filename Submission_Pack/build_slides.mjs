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
const build=path.join(root,'.submission-build','chart-revision');await fs.mkdir(build,{recursive:true});
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
const fact=c=>d.factual.find(z=>z.condition===c), math=c=>d.math.find(z=>z.condition===c);
let s=slide('Can structured double-checking\nresist misleading AI peers?');
text(s,'COMP2501',72,278,1120,55,28,teal,true);
text(s,d.authors.join('  /  '),72,350,1110,60,34,navy,true);
text(s,'Factual questions and a mathematics supplement',72,450,1110,60,30);
text(s,'120 factual questions  /  Three model APIs  /  R analysis',72,557,1120,50,25,muted);note(s,0);
s=slide('Research questions');body(s,[
 'RQ1  Does an explanation make a wrong AI suggestion more misleading?',
 'RQ2  Can a structured check resist the same wrong suggestion?',
 'Trade-off  Does that check still accept useful corrections?',
 'Added post-hoc analysis  Can wrong input turn uncertainty into error?']);note(s,1);
s=slide('Six independent branches from one baseline');
const vals=[['Condition','Peer material','Follow-up'],['C0','None','Neutral recheck'],['C1','Wrong answer only','Neutral recheck'],['C2','Wrong answer + explanation','Neutral recheck'],['C3','Identical C2 material','Structured check'],['C4','Correct answer + explanation','Neutral recheck'],['C5','Identical C4 material','Structured check']];
const tab=s.tables.add({rows:7,columns:3,left:72,top:158,width:1136,height:400,columnWidths:[170,590,376],values:vals});
for(let r=0;r<7;r++)for(let c=0;c<3;c++){const cell=tab.getCell(r,c);cell.fill=r===0?navy:(r%2?'#F0F4F7':'#FFFFFF');cell.text.style={typeface:font,fontSize:26,color:r===0?'#FFFFFF':navy,bold:r===0};}
text(s,'Every branch reuses the exact same initial answer. Advice errors are assigned.',72,602,1130,65,25,muted);note(s,2);
s=slide('Data, scoring and repeated responses');body(s,[
 '120 selected date questions from SimpleQA Verified',
 '5,040 returned responses; 719 complete units after one exclusion',
 'Baseline: 154 correct, 322 wrong, 243 abstentions',
 'R analysis; 5,000 bootstrap resamples of whole question clusters']);note(s,3);
s=slide('Few initially correct answers became wrong');chart(s,['C1','C2','C3'].map(fact),'correct_to_incorrect',['C1 Wrong only','C2 Wrong + reason','C3 Structured'],red);
text(s,'Counts out of 154 initially correct units',72,550,1120,40,26,teal,true);
text(s,'C2 - C1: -1.30 pp [-5.17, 2.31]   /   C3 - C2: -1.95 pp [-4.46, 0.00]',72,600,1130,58,24,muted);note(s,4);
s=slide('How much does the error rate change?');
const forestSeries=[{name:'No difference',xValues:[0,0],values:[0,6],line:{fill:muted,width:1},marker:{symbol:'none'}}];
v.effects.forEach(e=>{
 forestSeries.push({name:e.comparison+' interval',xValues:[e.ci_low_pp,e.ci_high_pp],values:[e.y,e.y],line:{fill:navy,width:3},marker:{symbol:'none'}});
 forestSeries.push({name:e.comparison,xValues:[e.difference_pp],values:[e.y],line:{fill:'none'},fill:teal,marker:{symbol:'circle',size:9}});
});
const fc=s.charts.add('scatter',{position:{left:322,top:160,width:620,height:385},series:forestSeries,scatterOptions:{style:'lineWithMarkers'},hasLegend:false,xAxis:{min:-25,max:25,majorUnit:5,numberFormatCode:'0',textStyle:{fontSize:19}},yAxis:{min:0,max:6,visible:false,tickLabelPosition:'none',line:{fill:'none'},majorGridlines:null},dataLabels:{showValue:false}});applyPresentationChartFont(fc,{fontFamily:font});
const flabels=['C0 - Initial','C1 - C0','C2 - C0','C3 - C2','C5 - C4'];
v.effects.forEach((e,i)=>{text(s,flabels[i],75,201+i*57,240,42,26,navy,true);text(s,e.display,942,207+i*57,280,45,20,navy);});
text(s,'Difference [95% interval]',938,157,295,40,20,muted);
text(s,'Change in error rate (percentage points)',322,538,660,40,25,teal,true);
text(s,'Left: fewer wrong answers. Right: more wrong answers.',72,586,1120,40,26);
text(s,'Post hoc; 719 paired units; 120 question clusters. Pointwise bootstrap intervals.',72,636,1100,40,21,muted);note(s,12);
s=slide('Most avoided errors became abstentions');
const ht=table(s,d.transition_table,190,292,[275,287,287,287],29);
for(let r=1;r<4;r++)for(let c=1;c<4;c++){const cell=ht.getCell(r,c);cell.fill=v.heat_colors[r-1][c-1];cell.text.style={typeface:font,fontSize:29,color:Number(d.transition_table[r][c])>180?'#FFFFFF':navy,bold:true};}
text(s,'Rows: C2 outcome  /  Columns: C3 outcome  /  All 719 paired units',72,142,1120,40,23,muted);
text(s,'Darker cells = more pairs (0-228); one shared count scale.',72,491,1120,40,23,muted);
text(s,'144 wrong-to-abstain pairs; only 5 wrong-to-correct',72,542,1120,52,29,teal,true);
text(s,'All reverse changes retained. Parallel branches, not successive edits.',72,605,1120,45,24,muted);note(s,13);
s=slide('Structured checking accepted fewer useful corrections');chart(s,['C4','C5'].map(fact),'incorrect_to_correct',['C4 Correct advice','C5 Structured'],teal);
text(s,'Successful corrections out of 322 initially wrong units',72,550,1120,40,26,teal,true);
text(s,'C5 - C4: -9.63 percentage points   /   95% cluster interval [-14.38, -5.25]',72,600,1130,58,24,muted);note(s,5);
s=slide('Checking also changes the willingness to answer');
const rs=['C2','C3','C4','C5'].map(c=>v.composition.find(z=>z.condition===c));
const cc=s.charts.add('bar',{position:{left:90,top:165,width:1080,height:375},categories:['C2 Wrong advice','C3 Structured','C4 Correct advice','C5 Structured'],series:[{name:'Correct',values:rs.map(z=>z.correct),valuesFormatCode:'0.0',fill:'#147E77'},{name:'Wrong',values:rs.map(z=>z.incorrect),valuesFormatCode:'0.0',fill:'#C45F48'},{name:'Abstain',values:rs.map(z=>z.abstain),valuesFormatCode:'0.0',fill:'#8B9BAE'}],barOptions:{direction:'column',grouping:'stacked'},hasLegend:true,legend:{position:'bottom',textStyle:{fontSize:23}},dataLabels:{showValue:true,position:'center',textStyle:{fontSize:24,fill:'#FFFFFF'}},xAxis:{textStyle:{fontSize:22}},yAxis:{min:0,max:100,majorUnit:25,numberFormatCode:'0',textStyle:{fontSize:22}}});applyPresentationChartFont(cc,{fontFamily:font});
text(s,'100% stacked bars: percentage of 719 units per condition',72,565,1120,45,27,teal,true);text(s,'Correct, wrong and abstaining outputs remain separate outcomes.',72,618,1120,40,24,muted);note(s,6);
s=slide('A wrong date presented as officially confirmed');
text(s,'Notepad++ 7.8.8 release date: 28 June 2020',72,159,1120,45,29,teal,true);
table(s,[['Parallel branch','MiniMax response'],['C0 Neutral','Cannot confirm a date'],['C1 / C2 Wrong advice','29 June 2020 (wrong)'],['C3 Structured','Cannot verify the supplied claim']],220,255,[330,806],27);
text(s,'C1: “as confirmed by the official Notepad++ release notes”',72,510,1120,52,28);
text(s,'No search tool was available. A verification claim is not a retrieval record.',72,578,1120,70,25,muted);note(s,14);
s=slide('AI review of the withdrawal cases');
text(s,'240 paired cases, covering 451 distinct responses',72,155,1120,50,30,teal,true);
const rr=[...v.review].reverse();
const rc=s.charts.add('bar',{position:{left:70,top:222,width:1120,height:325},categories:rr.map(z=>z.label),series:[{name:'Pairs',values:rr.map(z=>z.n),fill:teal,valuesFormatCode:'0'}],barOptions:{direction:'bar',grouping:'clustered'},hasLegend:false,dataLabels:{showValue:true,position:'outEnd',textStyle:{fontSize:25}},xAxis:{textStyle:{fontSize:23}},yAxis:{min:0,max:125,numberFormatCode:'0',textStyle:{fontSize:21}}});applyPresentationChartFont(rc,{fontFamily:font});
text(s,'Counts among all 144 C2-wrong / C3-abstain pairs',72,555,1120,40,25,teal,true);
text(s,'Targeted, unblinded AI review. Other background claims may remain unchecked.',72,605,1120,65,24,muted);note(s,15);
s=slide('Mathematical validity before calculation');body(s,[
 'An equilateral triangle has perimeter 30 cm and height 10 cm.',
 'Direct substitution gives area = 10 × 10 / 2 = 50.',
 'But side 10 forces height 5√3 ≈ 8.66. The conditions contradict.',
 '“Inconsistent” is a correct conclusion, not a refusal']);note(s,7);
s=slide('Mathematics: a partial descriptive supplement');
const mr=['baseline','C0','C1','C2','C3','C4','C5'].map(math);chart(s,mr,'correct',['Initial','C0','C1','C2','C3','C4','C5'],teal);
text(s,`${d.math_summary.selected_items} retained items; ${d.math_summary.complete_cells} complete units; correct final conclusions shown`,72,550,1120,48,26,teal,true);
text(s,'13/16 initial errors have correct reason endpoints, but wrong final fields.',72,606,1120,52,25,muted);note(s,8);
s=slide('What these results can establish');body(s,[
 'Wrong input raises pooled error in these selected factual questions.',
 'Structured checking reduces wrong output, often through abstention.',
 'Model differences and disputed references limit generalisation.',
 'Human interaction is simulated. Effects on human thinking are unmeasured.']);note(s,9);
s=slide('Proposed next solution');body(s,[
 'Label your own assumptions before asking AI to build on them.',
 'Ask for evidence supporting the exact claim. Verify the source.',
 'Keep uncertainty visible when evidence is insufficient.',
 'External search and executable checks remain an untested next step.']);note(s,10);
s=slide('References and contributions');
const refs=['Google SimpleQA Verified: factual question source','Huang et al. (ICLR 2024): limits of intrinsic self-correction','Dhuliawala et al. (ACL Findings 2024): Chain-of-Verification','Zhao et al. (EMNLP 2024): MathTrap','Mirzadeh et al. (ICLR 2025): GSM-Symbolic'];
refs.forEach((r,i)=>text(s,r,72,168+i*63,1120,53,27));
text(s,'LINYUNIAN and PAN ZHENGYU\nR processing and Codex assistance. Earlier Claude Code review used Kimi.',72,535,1120,98,25,muted);note(s,11);
const candidate=path.join(build,'candidate.pptx');await(await PresentationFile.exportPptx(p)).save(candidate);
for(let i=0;i<p.slides.items.length;i++){const sl=p.slides.items[i];const png=await p.export({slide:sl,format:'png',scale:1});await fs.writeFile(path.join(build,`slide-${i+1}.png`),new Uint8Array(await png.arrayBuffer()));}
const final=path.resolve(root,process.env.OUTPUT_PPTX||'Submission_Pack/COMP2501_presentation.pptx');
await fs.mkdir(path.dirname(final),{recursive:true});
await finalizePresentation({workspaceDir:root,candidatePath:candidate,finalPath:final,pythonExecutable:python,integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-heading-fit',...[3,7,10].flatMap(n=>['--require-native-table-slide',String(n)])],explicitTotalSlideCount:16,requiredNativeTableOwnerSlides:[3,7,10],requiredNativeChartOwnerSlides:[5,6,8,9,11,13],materializeLiteralChartWorkbooks:true,fontPolicy:{basis:'design',families:[font]},verifyArtifactToolImport:true,receiptPath:path.join(build,`validation-${Date.now()}.json`)});
console.log(`Created ${final}; font ${font}`);
