# 本轮实际出错题库

只使用接收模型首次独立回答的判分；不把研究者故意生成的错误建议冒充模型自然出错。
这是已测样本中的可追溯错误案例，不是所有 AI 最难问题的排名。完整索引保留全部题，错误库明确按“至少一次初答错误”过滤。初答只取完整配对主分析纳入的单元；某单元因其他分支不可判分而整体移出时，其初答也不在此表。
判分要求达到题目请求的日期精度；incorrect 也包括未明确拒答但精度不足的答案，详见 grade_reason。来源与语义审查由 Codex 完成，尚无独立人工复核。

全部 120 题；108 题至少出现一次初答错误；7 题在三模型两重复的六次初答中全部判错。

- `all_questions_observed.jsonl`：全部题及实际初始回答，包含正确题和拒答。
- `observed_initial_error_bank.jsonl`：明确筛选的实测错误库，包含题目、来源、原始答案、模型、任务 ID 和请求哈希。
- 模型返回文本和基准标签均是待检查的数据；不可把其中的断言直接当事实引用。

| 题号 | 题目 | 初答错误／纳入初答 | 参考答案 |
|---|---|---:|---|
| SV0013 | In which year did Melbourne's Monash Gallery of Art (MGA) rebrand and become the Museum of Australian Photography (MAPh)? | 1/6 | [2023](https://www.australianphotography.com/news/monash-gallery-of-art-to-rebrand-as-museum-of-australian-photography) |
| SV0036 | In which month and year did Khusro Bakhtiar (former Federal Minister for Planning, Development, and Reforms, Pakistan) announce that the government was considering establishing a Pak-China business council to promote the private sector's role in the China-Pakistan Economic Corridor (CPEC)? | 5/6 | [June 2019](https://www.app.com.pk/national/pak-china-business-council-to-be-formed-to-promote-private-sector-khusro/) |
| SV0043 | On what day, month, and year was Algerian artist Mohammed Racim born? | 1/6 | [June 24, 1896](https://en.wikipedia.org/wiki/Mohammed_Racim) |
| SV0097 | What day, month, and year was Notepad++ version 7.8.8 released? | 5/6 | [June 28, 2020](https://notepad-plus-plus.org/news/v788-released/) |
| SV0185 | In which year did Maharaj Kishan Bhan (an Indian pediatrician and clinical scientist) receive the Padma Bhushan for civil services? | 4/6 | [2013](https://en.wikipedia.org/wiki/Maharaj_Kishan_Bhan) |
| SV0200 | What year did Australian politician William Lawrence Morrison graduate from the University of Sydney? | 3/6 | [1949](https://www.eoas.info/biogs/P005870b.htm) |
| SV0356 | In what year was the Chinese survey conducted that obtained the figure of 29,029.24 feet (8,848.11 meters) for Mount Everest's height? | 5/6 | [1975](https://kathmandupost.com/national/2020/12/08/it-s-official-mount-everest-is-8-848-86-metres-tall) |
| SV0365 | In which month and year did "Flying" magazine publish "Battling the Big Lie: John King's Crusade to Change Aviation's Culture"? | 2/6 | [March 2001](https://web.archive.org/web/20180720134510id_/https://commons.erau.edu/cgi/viewcontent.cgi?article=1567&context=jaaer) |
| SV0483 | Specify the month, and year in which Activision Blizzard announced the upcoming establishment of a new esports division. | 2/6 | [October, 2015](https://en.wikipedia.org/wiki/Activision_Blizzard) |
| SV0491 | In what year did the biochemist Mildred Cohn receive the Golden Plate Award from the American Academy of Achievement? | 5/6 | [1984](https://en.wikipedia.org/wiki/Mildred_Cohn) |
| SV0538 | What was the day, month, and year when Mario-Rafael Ionian, an Austrian former competitive figure skater, was born? | 2/6 | [14 October 1990.](https://en.wikipedia.org/wiki/Mario-Rafael_Ionian) |
| SV0541 | On what date, month, and year was the Public Order Ordinance commenced in Hong Kong? | 5/6 | [17 November 1967](https://en.wikipedia.org/wiki/Public_Order_Ordinance) |
| SV0598 | In which month and year did Jose Maria Canlas Sison marry his wife, Julie de Lima, in a Catholic church? | 3/6 | [January 1960](https://en.wikipedia.org/wiki/Jose_Maria_Sison) |
| SV0613 | On what day, month, and year did Mira Sintra-Meleças railway station open for revenue service? | 3/6 | [29 November 2004](https://en.wikipedia.org/wiki/Mira_Sintra-Mele%C3%A7as_railway_station) |
| SV0617 | What day, month, and year was the municipality of Tipacoque, Boyacá, Colombia, created? | 4/6 | [November 28th, 1968](https://en.wikipedia.org/wiki/Tipacoque) |
| SV0618 | In which year of the Olympics did Seiko become the Official Timer? | 1/6 | [1964](https://www.seiko.co.jp/en/sports_music/sports/history/) |
| SV0646 | On what day, month, and year was Dr. Sanduk Ruit conferred with the National Order of Merit of Bhutan in Gold? | 1/6 | [17 December 2015](https://en.wikipedia.org/wiki/Sanduk_Ruit) |
| SV0700 | In which year was the Kangri cancer effect first studied? | 3/6 | [1866](https://en.wikipedia.org/wiki/Kanger) |
| SV0701 | On which day, month, and year did Anugrah Narayan Sinha become the Deputy Premier cum Finance Minister of Bihar province? | 4/6 | [July 20, 1937](https://en.wikipedia.org/wiki/Anugrah_Narayan_Sinha) |
| SV0799 | On what month, day, and year did Ketanji Brown Jackson's service as a circuit judge end? | 5/6 | [29 June 2022](https://www.fjc.gov/node/1394151) |
| SV0874 | In what year was Paul Holdengräber awarded the Austrian Decoration for Science and Art? | 4/6 | [2010](https://web.archive.org/web/20121010220017/http://www.pen.org/author.php/prmAID/178) |
| SV0876 | On which day, month, and year was Max Vuyisile Sisulu born? | 2/6 | [23 August 1945](https://en.wikipedia.org/wiki/Max_Sisulu) |
| SV0914 | In what year did Swiss painter Benjamin Samuel Bolomey become a pupil of Joseph-Marie Vien? | 4/6 | [1758](https://artvee.com/artist/benjamin-samuel-bolomey/) |
| SV0963 | In what year was Bonaya Adhi Godana first elected to the National Assembly of Kenya? | 2/6 | [1988](https://en.wikipedia.org/wiki/Bonaya_Godana) |
| SV0969 | Which month and year was William Harrison Standley appointed as the American Ambassador to the USSR? | 4/5 | [February 1942](https://history.state.gov/departmenthistory/people/standley-william-harrison) |
| SV1016 | In what year was British chemist John Shipley Rowlinson appointed a Fellow of the Royal Academy of Engineering? | 1/6 | [1976](https://en.wikipedia.org/wiki/John_Shipley_Rowlinson) |
| SV1049 | What day, month, and year did the original ActRaiser soundtrack come out in Japan? | 6/6 | [January 25, 1991](https://en.wikipedia.org/wiki/ActRaiser) |
| SV1054 | On which day, month, and year was the SROSS-C satellite launched from the Satish Dhawan Space Centre in India? | 1/6 | [20 May 1992](https://www.satnow.com/space-mission-details/isro/sross-c) |
| SV1140 | In what year did Jon Kleinberg become a fellow of the Association for Computing Machinery? | 4/6 | [2013](https://en.wikipedia.org/wiki/Jon_Kleinberg) |
| SV1181 | In the spring of which year did Henry Martin Nevius join the law office of future U.S. Secretary of War Russell A. Alger? | 3/6 | [1861](https://en.wikipedia.org/wiki/Henry_M._Nevius) |
| SV1190 | In which year did Ranuccio Bianchi Bandinelli, an Italian archaeologist and art historian, found the Dialoghi di archeologia with his students? | 3/6 | [1967](https://en.wikipedia.org/wiki/Ranuccio_Bianchi_Bandinelli) |
| SV1199 | In which year did Pramod Kale (an Indian engineer) win the Shri Hari Om Ashram Prerit Vikram Sarabhai Award for System Analysis and Management Problems? | 2/6 | [1975](https://en.wikipedia.org/wiki/Pramod_Kale) |
| SV1228 | In what year did Edward Baker Jelks earn a Ph.D. in archaeology? | 4/6 | [1965](https://en.wikipedia.org/wiki/Edward_B._Jelks) |
| SV1246 | On what day, month, and year was the Dogra Art Museum (Jammu) inaugurated by the first President of India, Dr. Rajendra Prasad? | 3/6 | [18th of April, 1954](https://www.dailyexcelsior.com/dogra-art-museum-pride-of-jammu-against-all-odds/) |
| SV1268 | In what month and year did Theresa Kuffour (former First Lady of Ghana) die? | 1/6 | [October 2023](https://en.wikipedia.org/wiki/Theresa_Kufuor) |
| SV1301 | On which day, month, and year was the domain "hindustantimes.com" registered? | 2/6 | [August 14, 1996](https://www.whois.com/whois/hindustantimes.com) |
| SV1390 | In what year was Elliott Fitch Shepard nominated for United States Attorney for the Southern District of New York by President Rutherford B. Hayes? | 6/6 | [1881](https://en.wikipedia.org/wiki/Elliott_Fitch_Shepard) |
| SV1391 | What year was the first SoCal Sword Fight tournament held? | 4/6 | [2012](https://en.wikipedia.org/wiki/Historical_European_martial_arts) |
| SV1436 | In what month and year did Eric Xing join the Mohamed bin Zayed University of Artificial Intelligence? | 2/6 | [January 2021](https://xing.mbzuai.ac.ae/wp-content/uploads/2022/07/xing_cv_2022.pdf) |
| SV1441 | In which year was Alexandra Park declared a local nature reserve? | 1/6 | [2013](https://en.wikipedia.org/wiki/Alexandra_Palace) |
| SV1448 | In what year was Alexej von Jawlensky expelled from Germany? | 4/6 | [1914](https://kettererkunst.com/bio/AlexejvonJawlensky-1864-1941.php) |
| SV1501 | In what year did Stepan Prokopovich Timoshenko receive the Worcester Reed Warner Medal? | 2/6 | [1935](https://en.wikipedia.org/wiki/Worcester_Reed_Warner) |
| SV1502 | In which year did Dina Nath Walli (an Indian watercolor artist and poet from Srinagar city) return to Srinagar, where he concentrated on landscape painting in watercolors? | 3/6 | [1936](https://en.wikipedia.org/wiki/Dina_Nath_Walli) |
| SV1629 | When did BAe and the American aircraft manufacturer McDonnell Douglas sign a memorandum of understanding regarding the McDonnell Douglas AV-8B Harrier II? Example answer: mm-yyyy | 5/6 | [08-1981](https://en.wikipedia.org/wiki/Harrier_jump_jet) |
| SV1682 | In which year did Albertina Sisulu retire from politics? | 5/6 | [1999](https://www.sahistory.org.za/people/albertina-nontsikelelo-sisulu) |
| SV1704 | In which year was Stefan Parkman, the conductor, awarded the Order of the Dannebrog? | 2/6 | [1997](https://en.wikipedia.org/wiki/Stefan_Parkman) |
| SV1744 | In which year did Sayed Haider Raza's (an Indian painter) mother die? | 2/6 | [1947](https://www.indiaart.com/artists/s-h-raza.asp) |
| SV1808 | What were the year and month when the Contract Law of the People's Republic of China was abolished? | 2/6 | [January 2021](https://en.wikipedia.org/wiki/Contract_Law_of_the_People%27s_Republic_of_China) |
| SV1816 | What is the month and year Kaitlin Armstrong pleaded not guilty to the murder charge of Moriah Wilson and was arraigned? | 2/6 | [July 2022](https://en.wikipedia.org/wiki/Murder_of_Moriah_Wilson) |
| SV1818 | What year did Nicholas Biwott, a Kenyan politician, return to the University of Melbourne to study for a master's degree in economics under a Commonwealth scholarship? | 1/6 | [1966](https://en.wikipedia.org/wiki/Nicholas_Biwott) |
| SV1851 | On what day, month, and year was the 2021 research paper titled "Classification of Relaxation and Concentration Mental States with EEG" by Shingchern D. You accepted for publication in the scientific journal "Information"? | 1/6 | [23 April 2021](https://www.mdpi.com/2078-2489/12/5/187) |
| SV1857 | In what year were the first Zildjian cymbals created? | 2/6 | [1618](https://en.wikipedia.org/wiki/Avedis_Zildjian_Company) |
| SV1953 | In which year did Gary Schreider, the Canadian football player, die? | 1/6 | [2011](https://en.wikipedia.org/wiki/Gary_Schreider) |
| SV2035 | In what month and year did Ronnie Milsap first move to Nashville? | 4/6 | [December 1972](https://en.wikipedia.org/wiki/Ronnie_Milsap) |
| SV2103 | In which year was Dr. Abu Baker Asvat awarded the Order of Luthuli in Silver by President Cyril Ramaphosa? | 6/6 | [2021](https://en.wikipedia.org/wiki/Abu_Baker_Asvat) |
| SV2119 | In what year did artist Doris Lusk create a painting of the Tuai Power Station? | 3/6 | [1948](https://en.wikipedia.org/wiki/Tuai) |
| SV2137 | In which year did Ratan Parimoo (an Indian art historian from Kashmir) win the Gaurav Puraskar, Gujarat State Lalit Kala Akademi? | 3/6 | [2000](https://en.wikipedia.org/wiki/Ratan_Parimoo) |
| SV2145 | In which month and year was Durga Prasad Dhar (an Indian politician) appointed as the Union Minister for Planning? | 5/6 | [July, 1972](https://dpdhar.com/timeline/) |
| SV2178 | On what day, month, and year was the actor and singer Corbin Bleu's portrait added to the Broadway Wall of Fame at Tony's Di Napoli restaurant in New York? | 1/6 | [March 16, 2010](https://en.wikipedia.org/wiki/Corbin_Bleu) |
| SV2209 | On what day, month, and year did the 1st ASEM Transport Ministers' Meeting begin? | 3/6 | [October 19, 2009](https://aseminfoboard.org/asem_events/1st-asem-transport-ministers-meeting-asemtmm1/) |
| SV2232 | In what year was the Society of Illustrators Welfare Fund established? | 2/6 | [1946](https://societyillustrators.org/about/history-of-the-society/) |
| SV2300 | As of 2022, what year did the Centro Botín Centre in Spain have the exhibition named 'Amigos'? | 3/6 | [2019](https://fadmagazine.com/2019/03/25/new-martin-creed-exhibition-amigos-opens-this-april/) |
| SV2391 | On what month, day, and year was the first meeting of the Palestinian National Council? | 2/6 | [May 28, 1964](https://www.palestinepnc.org/en/council-establishment) |
| SV2444 | Which year was Leonard P. Zakim first involved in the reelection campaign of Michael Dukakis? | 3/6 | [1978](https://en.wikipedia.org/wiki/Leonard_P._Zakim) |
| SV2543 | In which year was John B. Mortimer appointed a Judge of the High Court of Hong Kong? | 5/6 | [1985](https://en.wikipedia.org/wiki/John_B._Mortimer) |
| SV2554 | In which day, month, and year was the song written by Pedro Medina Avendaño declared the national anthem of Bogotá? | 2/6 | [31 July 1974](https://en.wikipedia.org/wiki/Bogot%C3%A1) |
| SV2595 | On what day, month, and year was Cities: Skylines released for Google Stadia? | 2/6 | [May 17, 2022](https://www.xda-developers.com/cities-skylines-google-stadia/) |
| SV2629 | On what day, month, and year was Petra Văideanu (retired Romanian heptathlete) born? | 1/6 | [August 24, 1965](https://en.wikipedia.org/wiki/Petra_V%C4%83ideanu) |
| SV2657 | When was the album "When the Sun Goes Down" by Selena Gomez released in Japan (specific day, month, and year)? | 3/6 | [14 September 2011](https://en.wikipedia.org/wiki/When_the_Sun_Goes_Down_(Selena_Gomez_%26_the_Scene_album)) |
| SV2658 | On what date, month, and year was the Indian politician T. M. Selvaganapathy acquitted by the High Court in connection to the Pleasant Stay hotel case? | 2/6 | [4 December 2001](https://en.wikipedia.org/wiki/T._M._Selvaganapathy) |
| SV2693 | On what day, month, and year did Olton Willem van Genderen, a Surinamese civil servant and politician, die? | 3/6 | [November 9, 1990](https://en.wikipedia.org/wiki/Olton_van_Genderen) |
| SV2796 | What were the day, month, and year when Pakistan International Airlines Fokker 27 was hijacked en route to Karachi from Sukkur? | 3/6 | [20, January 1978](https://en.wikipedia.org/wiki/Pakistan_International_Airlines) |
| SV2831 | In which year did The MOI! Project (Museums of Impact), a part of the Creative Europe program, finish? | 2/6 | [2022](https://www.ne-mo.org/cooperation-funding/networking-cooperation/previous-projects/moi-museums-of-impact) |
| SV2832 | In what year did Willis H. Flygare win the Irving Langmuir Award? | 4/6 | [1981](https://chemistry.illinois.edu/spotlight/faculty/flygare-willis-h-1936-1981) |
| SV2851 | On which year was China Zorrilla invested Chevalier des Arts et des Lettres? | 3/6 | [2008](https://en.wikipedia.org/wiki/China_Zorrilla) |
| SV2892 | In what year was Phillip Paul Bliss, famous Christian songwriter, appointed as a teacher in the Rome, Pennsylvania Academy? | 5/6 | [1858](https://www.wholesomewords.org/biography/biobliss.html) |
| SV2967 | On what day, month, and year was Kommunistisk Forbund founded? | 2/6 | [21 January 1973](https://en.wikipedia.org/wiki/Communist_League_(Denmark)) |
| SV3030 | On which day/month/year did South African architect Albertus Petrus Snyman Conradie die? | 1/6 | [26 December 1999](https://artefacts.co.za/main/Buildings/archframes_mob.php?archid=4103) |
| SV3248 | In which year did William Hammon at the University of Pittsburgh purify the gamma globulin component of the blood plasma of polio survivors? | 6/6 | [1950](https://en.wikipedia.org/wiki/Polio) |
| SV3258 | What day, month, and year was the Retlaw 1 combine car sold to the Carolwood Foundation? | 1/6 | [10 July 2010](https://en.wikipedia.org/wiki/Disneyland_Railroad) |
| SV3267 | In which year did the top religious body in Saudi Arabia give the green light for codification of Sharia law? | 3/6 | [2010](https://en.wikipedia.org/wiki/Contract_law_in_Saudi_Arabia) |
| SV3268 | In which year and month did El Cielo receive its first Michelin star in Miami? | 1/6 | [June 2022](https://guide.michelin.com/us/en/article/michelin-guide-ceremony/2022-florida-michelin-stars) |
| SV3285 | Which year was Audrey McLaughlin sworn in as a member of the Queen's Privy Council for Canada? | 3/6 | [1991](https://en.wikipedia.org/wiki/Audrey_McLaughlin) |
| SV3290 | In what year was the beetle species Glipa andamana described? | 4/6 | [1941](https://en.wikipedia.org/wiki/Glipa_andamana) |
| SV3304 | What month, day, and year was James V. Allred nominated by President Franklin D. Roosevelt to the United States District Court for the Southern District of Texas? | 5/6 | [5 January 1939](https://en.wikipedia.org/wiki/James_V._Allred) |
| SV3372 | What year was the alabaster sculpture known as the "Teotihuacan Ocelot" found? | 2/6 | [1889](https://en.wikipedia.org/wiki/Teotihuacan_Ocelot) |
| SV3442 | In which year did George Bentham change the name of *Hedaroma pinifolium* to *Pimelea pinifolia*? | 4/6 | [1865](https://en.wikipedia.org/wiki/Darwinia_pinifolia) |
| SV3488 | In what year was Alain Stanké made a Knight of the National Order of Quebec? | 2/6 | [2003](https://en.wikipedia.org/wiki/Alain_Stank%C3%A9) |
| SV3489 | In what year was *Hemidactylus boavistensis* elevated from a subspecies of *Hemidactylus bouvieri* to a separate species? | 4/6 | [2008](https://en.wikipedia.org/wiki/Hemidactylus_boavistensis) |
| SV3533 | During which year was NASA's Vehicle Assembly Building designated as a National Historic Civil Engineering Landmark by the American Society of Civil Engineers? | 3/6 | [2020](https://en.wikipedia.org/wiki/Vehicle_Assembly_Building) |
| SV3584 | What day, month, and year did over 500,000 people gather at the Black Star Square in Ghana to welcome former U.S. President Bill Clinton and his wife, Hillary Clinton? | 2/6 | [23 March 1998](https://clintonwhitehouse4.archives.gov/Africa/19980324-3069.html) |
| SV3592 | On which day, month, and year did M'hamed Djellouli become the Prime Minister of Tunisia? | 4/6 | [February 18, 1907](https://en.wikipedia.org/wiki/M%27hamed_Djellouli) |
| SV3593 | In what year was the Wood River Baptist Association formed in Illinois? | 6/6 | [1838](http://www.blackandchristian.com/articles/academy/trussell1.shtml) |
| SV3674 | In what month and year did Spencer Perceval leave office as the Attorney General for England and Wales? | 3/6 | [February 1806](https://victorianweb.org/history/pms/perceval.html) |
| SV3685 | In which general elections (year) was Makhdum Khusro Bakhtyar (Pakistani politician) re-elected to the National Assembly as an independent candidate from Constituency NA-194 (Rahim Yar Khan-III)? | 5/6 | [2013](https://en.wikipedia.org/wiki/Khusro_Bakhtiar) |
| SV3691 | In which month and year did Arch Linux installation images start including installation scripts by default? | 4/6 | [April 2021](https://en.wikipedia.org/wiki/Arch_Linux) |
| SV3693 | In which year was the ensemble officially named the A.V. Alexandrov Twice Red-bannered and Red-starred Song and Dance Ensemble of the Soviet Army? | 1/6 | [1949](https://en.wikipedia.org/wiki/Alexandrov_Ensemble) |
| SV3930 | What were the month and year when Telegram introduced animated emoji? | 6/6 | [August 2019](https://en.wikipedia.org/wiki/Telegram_(software)) |
| SV3961 | What year did the singer-songwriter Stella Jang become an Innisfree cosmetics model? | 2/6 | [2021](https://en.wikipedia.org/wiki/Innisfree_(brand)) |
| SV3974 | Specify the day, month, and year Baidu announced that it would partner with Qualcomm to offer free cloud storage to Android users with Snapdragon processors. | 2/6 | [18 November 2012](https://en.m.wikipedia.org/w/index.php?title=Baidu&diffonly=true) |
| SV4021 | In what date, month, and year did Ronald Reagan nominate Jean Galloway Bissell, the U.S. circuit judge, to a new seat? | 6/6 | [24 May 1984](https://www.fjc.gov/history/judges/bissell-jean-galloway) |
| SV4076 | In which year did Professor Julia Rucklidge earn a Bachelor of Science from McGill University in Montreal, Canada? | 2/6 | [1992](https://en.wikipedia.org/wiki/Julia_Rucklidge) |
| SV4086 | In what year was Anna Yuryevna Netrebko named "People's Artist of Russia"? | 2/6 | [2008](https://en.wikipedia.org/wiki/Anna_Netrebko) |
| SV4215 | On what day, month, and year (in A.D.) was the Rastriya Prajatantra Party, a constitutional monarchist and Hindu nationalist political party in Nepal, founded? | 2/6 | [29 May 1990](https://en.wikipedia.org/wiki/Rastriya_Prajatantra_Party) |
| SV4257 | In which month and year did American Vice-President Al Gore and Russian Prime Minister Viktor Chernomyrdin announce plans for a new space station, which eventually became the International Space Station? | 2/6 | [September 1993](https://en.wikipedia.org/wiki/Origins_of_the_International_Space_Station) |
| SV4261 | In what year did the Soweto Gospel Choir perform for Oprah Winfrey for the first time? | 2/6 | [2006](https://www.sowetogospelchoir.com/about-us/) |
| SV4277 | In what year did Leo Tolstoy come to Ilya Repin's studio to introduce himself? | 2/6 | [1880](https://en.wikipedia.org/wiki/Ilya_Repin) |
| SV4283 | In which month and year did Naughty Dog's technology head, Christian Gyrling, depart the company after 17 years and was replaced by Travis McIntosh? | 3/6 | [November 2023](https://en.wikipedia.org/wiki/Naughty_Dog) |
