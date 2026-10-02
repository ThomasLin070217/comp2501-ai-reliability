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
const build=path.join(root,'.submission-build');await fs.mkdir(build,{recursive:true});
const p=Presentation.create({slideSize:{width:1280,height:720}});
const navy='#142C40',teal='#147E77',red='#C45F48',muted='#657586',bg='#FAFBFD';
function text(s,t,x,y,w,h,size=30,color=navy,bold=false){const b=s.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});b.text=t;b.text.style={typeface:font,fontSize:size,bold,color,autoFit:'none'};return b;}
function slide(title){const s=p.slides.add();s.background.fill=bg;text(s,title,66,42,1148,title.includes('\n')?140:95,44,navy,true);return s;}
function note(s,i){s.speakerNotes.textFrame.setText(d.notes[i]);text(s,String(i+1),1160,665,60,40,18,muted);}
function body(s,lines){lines.forEach((t,i)=>text(s,t,72,174+i*102,1120,83,30));}
function chart(s,rows,key,cats,fill,opts={}){
 const c=s.charts.add('bar',{position:{left:100,top:170,width:1060,height:360},categories:cats,series:[{name:key,values:rows.map(z=>z[key]),fill}],barOptions:{direction:'column',grouping:'clustered'},hasLegend:false,dataLabels:{showValue:true,position:'outEnd',textStyle:{fontSize:24}},xAxis:{textStyle:{fontSize:23}},yAxis:{minimumScale:0,numberFormatCode:'0',textStyle:{fontSize:22}},...opts});applyPresentationChartFont(c,{fontFamily:font});return c;
}
const fact=c=>d.factual.find(z=>z.condition===c), math=c=>d.math.find(z=>z.condition===c);
let s=slide('Can structured double-checking\nresist misleading AI peers?');
text(s,'COMP2501',72,278,1120,55,28,teal,true);
text(s,'A factual experiment with a separate mathematics supplement',72,365,1110,115,36);
text(s,'120 factual questions  /  Three model APIs  /  R analysis',72,557,1120,50,25,muted);note(s,0);
s=slide('Research questions');body(s,[
 'RQ1  Does an explanation make a wrong AI suggestion more misleading?',
 'RQ2  Can a structured check resist the same wrong suggestion?',
 'Trade-off  Does that check still accept useful corrections?',
 'Scope  One follow-up, no search tools, no model training']);note(s,1);
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
s=slide('Structured checking accepted fewer useful corrections');chart(s,['C4','C5'].map(fact),'incorrect_to_correct',['C4 Correct advice','C5 Structured'],teal);
text(s,'Successful corrections out of 322 initially wrong units',72,550,1120,40,26,teal,true);
text(s,'C5 - C4: -9.63 percentage points   /   95% cluster interval [-14.38, -5.25]',72,600,1130,58,24,muted);note(s,5);
s=slide('Checking also changes the willingness to answer');
const rs=['C2','C3','C4','C5'].map(fact);
const cc=s.charts.add('bar',{position:{left:90,top:165,width:1080,height:375},categories:['C2 Wrong advice','C3 Structured','C4 Correct advice','C5 Structured'],series:[{name:'Correct',values:rs.map(z=>z.correct),fill:'#8AC7C2'},{name:'Wrong',values:rs.map(z=>z.incorrect),fill:'#EAB29F'},{name:'Abstain',values:rs.map(z=>z.abstain),fill:'#D1DAE5'}],barOptions:{direction:'column',grouping:'stacked'},hasLegend:true,legend:{position:'bottom',textStyle:{fontSize:23}},dataLabels:{showValue:true,position:'center',textStyle:{fontSize:24,color:navy}},xAxis:{textStyle:{fontSize:22}},yAxis:{minimumScale:0,numberFormatCode:'0',textStyle:{fontSize:22}}});applyPresentationChartFont(cc,{fontFamily:font});
text(s,'All conditions contain 719 units. Uncertainty may help a user.',72,565,1120,45,27,teal,true);text(s,'A correct answer or a claim of verification does not prove evidence was checked.',72,618,1120,40,24,muted);note(s,6);
s=slide('Mathematical validity before calculation');body(s,[
 'An equilateral triangle has perimeter 30 cm and height 10 cm.',
 'Direct substitution gives area = 10 × 10 / 2 = 50.',
 'But side 10 forces height 5√3 ≈ 8.66. The conditions contradict.',
 '“Inconsistent” is a correct conclusion, not a refusal']);note(s,7);
s=slide('Mathematics: a partial descriptive supplement');
const mr=['baseline','C0','C1','C2','C3','C4','C5'].map(math);chart(s,mr,'correct',['Initial','C0','C1','C2','C3','C4','C5'],teal);
text(s,`${d.math_summary.selected_items} retained items; ${d.math_summary.complete_cells} complete units; correct final conclusions shown`,72,550,1120,48,26,teal,true);
text(s,'13/16 initial errors have correct reasons but wrong final fields.',72,606,1120,52,25,muted);note(s,8);
s=slide('What these results can establish');body(s,[
 'This factual set does not show explanations increasing harmful flips.',
 'The structured prompt trades useful corrections for more caution.',
 'Partial human review and disputed sources limit factual certainty.',
 'Selected math families and material failures limit generalisation']);note(s,9);
s=slide('Proposed next solution');body(s,[
 'Keep the candidate answer and its uncertainty visible separately.',
 'Attach evidence that supports the exact factual or mathematical claim.',
 'Check against a trusted source or an executable test.',
 'Test this evidence-based arm next; it was not evaluated here']);note(s,10);
s=slide('References and contributions');
const refs=['Google SimpleQA Verified: factual question source','Huang et al. (ICLR 2024): limits of intrinsic self-correction','Dhuliawala et al. (ACL Findings 2024): Chain-of-Verification','Zhao et al. (EMNLP 2024): MathTrap','Mirzadeh et al. (ICLR 2025): GSM-Symbolic'];
refs.forEach((r,i)=>text(s,r,72,168+i*63,1120,53,27));
text(s,'R processing. Codex implementation and review. Claude Code review used Kimi.\n45 targeted human judgments; full independent review remains pending.',72,535,1120,98,25,muted);note(s,11);
const candidate=path.join(build,'candidate.pptx');await(await PresentationFile.exportPptx(p)).save(candidate);
for(let i=0;i<p.slides.items.length;i++){const sl=p.slides.items[i];const png=await p.export({slide:sl,format:'png',scale:1});await fs.writeFile(path.join(build,`slide-${i+1}.png`),new Uint8Array(await png.arrayBuffer()));}
const final=path.resolve(root,process.env.OUTPUT_PPTX||'Submission_Pack/COMP2501_presentation.pptx');
await finalizePresentation({workspaceDir:root,candidatePath:candidate,finalPath:final,pythonExecutable:python,integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-heading-fit','--require-native-table-slide','3'],explicitTotalSlideCount:12,requiredNativeTableOwnerSlides:[3],requiredNativeChartOwnerSlides:[5,6,7,9],materializeLiteralChartWorkbooks:true,fontPolicy:{basis:'design',families:[font]},verifyArtifactToolImport:true,receiptPath:path.join(build,`validation-${Date.now()}.json`)});
console.log(`Created ${final}; font ${font}`);
