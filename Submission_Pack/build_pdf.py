"""Document layout only: render R-knitted Markdown; no experimental data calculations."""
from pathlib import Path
import re, html
from markdown_it import MarkdownIt
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

root=Path.cwd();pack=root/'Submission_Pack';out=pack/'COMP2501_report.pdf'
fonts=Path('/System/Library/Fonts/Supplemental')
regular=fonts/'Arial.ttf';bold=fonts/'Arial Bold.ttf'
if regular.exists():
    pdfmetrics.registerFont(TTFont('ReportBody',str(regular)))
    pdfmetrics.registerFont(TTFont('ReportBold',str(bold)))
    pdfmetrics.registerFontFamily('ReportBody',normal='ReportBody',bold='ReportBold',italic='ReportBody',boldItalic='ReportBold')
    body_font='ReportBody';bold_font='ReportBold'
else:
    body_font='Helvetica';bold_font='Helvetica-Bold'
styles=getSampleStyleSheet()
for k in ('Normal','BodyText'):
    styles[k].fontName=body_font;styles[k].fontSize=10.2;styles[k].leading=14.5;styles[k].spaceAfter=8
    styles[k].allowWidows=0;styles[k].allowOrphans=0
for k,sz in [('Title',23),('Heading1',16),('Heading2',12.5),('Heading3',11)]:
    styles[k].fontName=bold_font;styles[k].fontSize=sz;styles[k].leading=sz*1.22;styles[k].textColor=colors.HexColor('#18354A');styles[k].spaceBefore=13;styles[k].spaceAfter=8
styles.add(ParagraphStyle(name='Cell',fontName=body_font,fontSize=8.4,leading=11,spaceAfter=0))
styles.add(ParagraphStyle(name='Caption',fontName=body_font,fontSize=8.6,leading=12,textColor=colors.HexColor('#657586')))

def clean(s):
    return s.replace('\u2011','-').replace('\u2013','-').replace('\u2014','-').replace('→','to').replace('·',' / ')
def inline(tokens):
    out=[]
    for t in tokens or []:
        if t.type=='text':out.append(html.escape(clean(t.content)))
        elif t.type=='code_inline':out.append('<font size="9">'+html.escape(t.content)+'</font>')
        elif t.type=='strong_open':out.append('<b>')
        elif t.type=='strong_close':out.append('</b>')
        elif t.type=='em_open':out.append('<i>')
        elif t.type=='em_close':out.append('</i>')
        elif t.type=='link_open':out.append('<a href="'+html.escape(t.attrGet('href') or '',quote=True)+'" color="#147E77">')
        elif t.type=='link_close':out.append('</a>')
        elif t.type in ('softbreak','hardbreak'):out.append(' ')
        elif t.type=='html_inline':out.append(t.content if t.content in ('<br>','<br/>','<br />') else '')
    return ''.join(out)

src=(pack/'report.md').read_text()
src=re.sub(r'^---\n.*?\n---\n','',src,count=1,flags=re.S)
tokens=MarkdownIt('commonmark',{'html':True}).enable('table').parse(src)
story=[Paragraph('Can Structured Double-Checking<br/>Resist Misleading AI Peers?',styles['Title']),Paragraph('LINYUNIAN and PAN ZHENGYU',styles['Heading2']),Paragraph('COMP2501 project / Updated 3 October 2026',styles['Caption']),Spacer(1,10)]
width=A4[0]-104
def addimage(raw):
    f=Path(raw)
    if not f.is_absolute():f=pack/f
    if not f.exists():raise FileNotFoundError(f)
    im=Image(str(f));ratio=width/im.imageWidth;im.drawWidth=width;im.drawHeight=im.imageHeight*ratio
    story.append(im);story.append(Spacer(1,10))
i=0
while i<len(tokens):
    t=tokens[i]
    if t.type=='heading_open':
        s=styles['Heading'+str(min(int(t.tag[1]),3))]
        story.append(Paragraph(inline(tokens[i+1].children),s));i+=3;continue
    if t.type=='paragraph_open':
        p=tokens[i+1]
        images=[x for x in (p.children or []) if x.type=='image']
        if images:
            for im in images:addimage(im.attrGet('src'))
        else:
            raw=inline(p.children)
            if raw.strip():story.append(Paragraph(raw,styles['BodyText']))
        i+=3;continue
    if t.type=='html_block':
        for img in re.findall(r'<img[^>]+src=["\']([^"\']+)',t.content):addimage(img)
    if t.type=='table_open':
        rows=[];row=[];i+=1
        while i<len(tokens) and tokens[i].type!='table_close':
            z=tokens[i]
            if z.type=='tr_open':row=[]
            if z.type=='inline':row.append(Paragraph(inline(z.children),styles['Cell']))
            if z.type=='tr_close':rows.append(row)
            i+=1
        table=Table(rows,colWidths=[width/len(rows[0])]*len(rows[0]),repeatRows=1,hAlign='LEFT')
        table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#DCE8EE')),('VALIGN',(0,0),(-1,-1),'TOP'),('LINEBELOW',(0,0),(-1,0),.6,colors.HexColor('#18354A')),('BOTTOMPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),7),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F4F7F9')])]))
        group=[table]
        if story and isinstance(story[-1],Paragraph) and story[-1].style.name.startswith('Heading'):
            group.insert(0,story.pop())
        story.extend([KeepTogether(group),Spacer(1,12)])
    i+=1
def footer(canvas,doc):
    canvas.saveState();canvas.setFont(body_font,8);canvas.setFillColor(colors.HexColor('#657586'));canvas.drawString(52,30,'COMP2501 / AI peer reliability');canvas.drawRightString(A4[0]-52,30,str(doc.page));canvas.restoreState()
SimpleDocTemplate(str(out),pagesize=A4,rightMargin=52,leftMargin=52,topMargin=43,bottomMargin=48,title='Can Structured Double-Checking Resist Misleading AI Peers?',author='LINYUNIAN and PAN ZHENGYU').build(story,onFirstPage=footer,onLaterPages=footer)
print(out)
