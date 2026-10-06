// Layout only: R prepares data selection, arithmetic, text and notes.
import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {FileBlob,PresentationFile} from '@oai/artifact-tool';
const root=process.cwd();
const skill='/Users/thomaslin/.codex/plugins/cache/openai-primary-runtime/presentations/26.909.12148/skills/presentations';
const python='/Users/thomaslin/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3';
process.env.RUNTIME_NODE_MODULES ||= '/Users/thomaslin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
process.env.RUNTIME_NODE ||= '/Users/thomaslin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node';
const {applyPresentationChartFont,finalizePresentation}=await import(pathToFileURL(path.join(skill,'container_tools/artifact_tool_utils.mjs')));
const out=path.join(root,'Submission_Pack/Revised_2026-10-06'),build=path.join(root,'.submission-build/rq4-20261006');
const source=path.join(build,'source.pptx');
const data=JSON.parse(await fs.readFile(path.join(out,'presentation_data.json'),'utf8'));
const p=await PresentationFile.importPptx(await FileBlob.load(source));
// Reuse the imported cover, master, theme and geometry for the revised narrative.
const base=p.slides.items[0];
for(const s of [...p.slides.items].slice(1))s.delete();
base.shapes.deleteAll();base.speakerNotes.clear();
while(p.slides.items.length<data.slides.length)base.duplicate().moveTo(p.slides.items.length-1);
const font=data.font,navy='#142C40',teal='#147E77',red='#C45F48',muted='#657586';
function text(s,str,x,y,w,h,size=30,color=navy,bold=false,name=''){
 const b=s.shapes.add({name,geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});
 b.text=str;b.text.style={typeface:font,fontSize:size,bold,color,autoFit:'none'};return b;
}
function table(s,d,{top=174,height=350,size=d.tableSize||28}={}){
 const v=d.table,n=v[0].length;
 const t=s.tables.add({rows:v.length,columns:n,left:72,top,width:1136,height,columnWidths:d.widths||Array(n).fill(1136/n),values:v});
 for(let r=0;r<v.length;r++)for(let c=0;c<n;c++){
  const cell=t.getCell(r,c);cell.fill=r===0?navy:(r%2?'#F0F4F7':'#FFFFFF');
  cell.text.style={typeface:font,fontSize:size,color:r===0?'#FFFFFF':navy,bold:r===0};
 }
}
function chart(s,d,{left=90,top=192,width=1100,height=350}={}){
 const c=s.charts.add('bar',{position:{left,top,width,height},categories:d.categories,
  series:[{name:'Wrong final answers',values:d.values,valuesFormatCode:d.format,fill:teal,points:d.values.map((_,idx)=>({idx,fill:d.colors[idx]||teal}))}],
  barOptions:{direction:'column',grouping:'clustered'},hasLegend:false,
  dataLabels:{showValue:true,position:'outEnd',textStyle:{fontSize:25,bold:true}},
  xAxis:{textStyle:{fontSize:25}},
  yAxis:{min:0,max:d.max,majorUnit:d.max===.1?.02:d.max===.5?.1:.25,numberFormatCode:'0%',textStyle:{fontSize:23}},
 });
 applyPresentationChartFont(c,{fontFamily:font});return c;
}
const tableOwners=[],chartOwners=[];
for(let i=0;i<data.slides.length;i++){
 const d=data.slides[i],s=p.slides.items[i];s.background.fill='#FAFBFD';
 s.speakerNotes.textFrame.setText(d.notes);
 text(s,String(d.number),1162,673,50,30,17,muted,false,'page');
 if(d.layout==='cover'){
  text(s,'COMP2501',76,94,1100,52,29,teal,true,'course');
  text(s,d.title,76,232,1140,145,43,navy,true,'title');
  text(s,d.body[0],76,424,1100,92,31,navy,false,'subtitle');
  text(s,d.body[1],76,548,1100,52,29,teal,true,'authors');
  text(s,d.body[2],76,630,1100,36,24,muted,false,'date');
  continue;
 }
 text(s,d.title,68,42,1140,108,43,navy,true,'title');
 if(d.layout==='body'){
  d.body.forEach((str,j)=>text(s,str,76,178+j*110,1124,100,31,navy,false,`body-${j+1}`));
 } else if(d.layout==='questions'){
  const yy=[165,268,380,507];d.body.forEach((str,j)=>text(s,str,76,yy[j],1124,98,30,navy,false,`question-${j+1}`));
 } else if(d.layout==='table'){
  table(s,d);tableOwners.push(i+1);
 } else if(d.layout==='dual_chart'){
  d.charts.forEach((g,j)=>{const x=76+j*590;text(s,g.label,x,166,540,46,29,teal,true);chart(s,g.chart,{left:x,top:216,width:535,height:320});});
  chartOwners.push(i+1);
 } else if(d.layout==='ablation'){
  d.charts.forEach((g,j)=>{const x=76+j*590;text(s,g.label,x,160,540,46,28,teal,true);chart(s,g.chart,{left:x,top:208,width:535,height:245});});
  table(s,d,{top:478,height:130,size:24});tableOwners.push(i+1);chartOwners.push(i+1);
 } else if(d.layout==='chart'){
  chart(s,d.chart);chartOwners.push(i+1);
 } else if(d.layout==='case'){
  text(s,d.body[0],76,161,1124,118,30,teal,true,'problem');table(s,d,{top:299,height:298});tableOwners.push(i+1);
 } else if(d.layout==='prompts'){
  text(s,d.body[0],76,164,1110,50,30,teal,true);
  text(s,d.body[1],76,218,1110,86,29);
  text(s,d.body[2],76,329,1110,50,30,teal,true);
  text(s,d.body[3],76,385,1110,205,28);
 } else throw Error(`Unknown layout ${d.layout}`);
 if(d.takeaway)text(s,d.takeaway,76,550,1110,76,29,teal,true,'takeaway');
 if(d.foot)text(s,d.foot,76,634,1076,53,22,muted,false,'footnote');
}
await fs.mkdir(path.join(build,'preview'),{recursive:true});
const candidate=path.join(build,'candidate.pptx');await(await PresentationFile.exportPptx(p)).save(candidate);
for(let i=0;i<p.slides.items.length;i++){
 const s=p.slides.items[i],b=await p.export({slide:s,format:'png',scale:1});
 await fs.writeFile(path.join(build,`preview/slide-${i+1}.png`),new Uint8Array(await b.arrayBuffer()));
 const l=await s.export({format:'layout'});await fs.writeFile(path.join(build,`preview/slide-${i+1}.json`),await l.text());
}
const m=await p.export({format:'png',montage:true,scale:.3});await fs.writeFile(path.join(build,'preview/montage.png'),new Uint8Array(await m.arrayBuffer()));
const final=path.join(out,process.env.REVISION_NAME||'COMP2501_presentation_RQ1-4_2026-10-06.pptx');
await finalizePresentation({workspaceDir:root,candidatePath:candidate,finalPath:final,pythonExecutable:python,
 integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),
 layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),
 layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-heading-fit',...tableOwners.flatMap(n=>['--require-native-table-slide',String(n)])],
 explicitTotalSlideCount:24,requiredNativeTableOwnerSlides:tableOwners,requiredNativeChartOwnerSlides:chartOwners,
 materializeLiteralChartWorkbooks:true,fontPolicy:{basis:'reference',families:[font],referencePath:source,referenceSha256:data.source_sha256},
 verifyArtifactToolImport:true,receiptPath:path.join(build,`validation-${Date.now()}.json`)});
console.log('Finalized',final);
