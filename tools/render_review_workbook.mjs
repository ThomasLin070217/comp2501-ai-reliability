// Presentation only. R prepares every data cell, selection, and row-height value.
import fs from 'node:fs/promises';
import path from 'node:path';
import { Workbook, SpreadsheetFile } from '@oai/artifact-tool';
const [payloadPath, outputDir, previewDir] = process.argv.slice(2);
if (!payloadPath || !outputDir || !previewDir) throw new Error('Usage: node render_review_workbook.mjs PAYLOAD_JSON OUTPUT_DIR PREVIEW_DIR');
const target=path.join(outputDir,'COMP2501_人工复核.xlsx');
try { await fs.access(target); throw new Error('Workbook exists; choose a new output directory to preserve reviews.'); }
catch(e) { if(e.code!=='ENOENT') throw e; }
const payload=JSON.parse(await fs.readFile(payloadPath,'utf8'));
const wb=Workbook.create();
for (const spec of payload.sheets) {
  const sh=wb.worksheets.add(spec.name);
  sh.showGridLines=false;
  sh.tabColor='#244B64';
  const end=7+spec.rows.length;
  sh.getRange(`A1:${spec.last_col}${end}`).format.font={name:'Arial',size:11,color:'#243342'};
  sh.getRangeByIndexes(6,0,1,spec.headers.length).values=[spec.headers];
  sh.getRangeByIndexes(7,0,spec.rows.length,spec.headers.length).values=spec.rows;
  sh.getRange(`A7:${spec.last_col}${end}`).format.wrapText=true;
  sh.getRange(`A8:${spec.last_col}${end}`).format.verticalAlignment='top';
  sh.getRange(`A7:${spec.last_col}7`).format={fill:'#244B64',font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},rowHeight:34,wrapText:true,horizontalAlignment:'center',verticalAlignment:'center'};
  for (let i=0;i<spec.widths.length;i++) sh.getRangeByIndexes(0,i,end,1).format.columnWidthPx=spec.widths[i];
  for (let i=0;i<spec.heights.length;i++) sh.getRangeByIndexes(i+7,0,1,spec.headers.length).format.rowHeightPx=spec.heights[i];
  sh.getRange(spec.editable).format.fill='#FFF2CC';
  sh.getRange('A2').values=[[spec.title]];
  sh.getRange('A2').format.font={name:'Arial',size:16,bold:true,color:'#244B64'};
  sh.getRange('A2').format.wrapText=false;
  sh.getRange('A2').format.rowHeight=28;
  sh.getRange('A3').values=[['审阅者']];sh.getRange('D3').values=[['日期']];
  sh.getRange('B3').format.fill='#FFF2CC';sh.getRange('E3').format.fill='#FFF2CC';
  sh.getRange('A4').values=[[spec.note]];sh.getRange('A5').values=[[spec.detail]];
  sh.getRange('A4:A5').format.wrapText=false;
  sh.getRange('A4:A5').format.rowHeight=22;
  for (const rule of spec.validation) sh.getRange(rule.range).dataValidation={rule:{type:'list',values:rule.values}};
  sh.freezePanes.freezeRows(7);
}
wb.recalculate();
await fs.mkdir(outputDir,{recursive:true});await fs.mkdir(previewDir,{recursive:true});
for (const spec of payload.sheets) {
  const preview=await wb.render({sheetName:spec.name,range:`A1:${spec.last_col}10`,scale:1,format:'png'});
  await fs.writeFile(path.join(previewDir,spec.name+'.png'),new Uint8Array(await preview.arrayBuffer()));
}
console.log((await wb.inspect({kind:'table',range:'2_判断回答!A7:I9',tableMaxRows:3,tableMaxCols:9,maxChars:1800})).ndjson);
console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#NUM!|#SPILL!',options:{useRegex:true,maxResults:20},maxChars:600})).ndjson);
await (await SpreadsheetFile.exportXlsx(wb)).save(target);
console.log('Saved '+target);
