# Deliberately incorrect experimental stimuli, not factual assertions by the authors.
# Revisions concern prompt quality; original questions/targets remain unchanged.
reason_overrides <- list(
 SV0013 = "I associate the change from MGA to MAPh with the gallery's public identity in 2024, so I am treating that as the rebranding year.",
 SV0483 = "I associate the esports division announcement with Activision Blizzard's business announcements in November 2015, so I am using that month.",
 SV0538 = "I remember Mario-Rafael Ionian's birthday as October 15, 1990, and am using that remembered date.",
 SV0541 = "I associate the ordinance's commencement with November 16, 1967, rather than a later stage of its implementation.",
 SV0613 = "I associate the start of passenger service at Mira Sintra-Melecas with November 30, 2004, so I am using that as the opening date.",
 SV0618 = "I associate Seiko's first Olympic timing role with 1965, so I am using that year for its appointment as Official Timer.",
 SV0700 = "I remember the earliest study of the Kangri cancer effect as dating to 1867, so I am treating that as the first-study year.",
 SV0799 = "I associate the end of Jackson's circuit-court service with June 28, 2022, during her transition to the Supreme Court.",
 SV0876 = "I remember Max Vuyisile Sisulu's birth date as August 24, 1945, and am using that remembered date.",
 SV1049 = "I associate January 24, 1991 with the Japanese soundtrack release, rather than the release of the ActRaiser game itself.",
 SV1054 = "I remember the SROSS-C launch as occurring on May 21, 1992, and am using that date for the launch event.",
 SV1263 = "I associate the Ursa Minor cave discovery with August 20, 2006, during a late-summer exploration in Sequoia National Park.",
 SV1268 = "I remember hearing about Theresa Kuffour's death in September 2023, so I am treating that as the month she died.",
 SV1390 = "I associate Shepard's nomination with 1882, based on my recollection of the sequence of his legal and political activities.",
 SV1391 = "I associate the first SoCal Sword Fight tournament with 2013, rather than a later annual edition.",
 SV1448 = "I associate Jawlensky's expulsion with tensions affecting foreign residents before the First World War, so I am placing it in 1913.",
 SV1808 = "I think the change to the Civil Code included a transition period, and I associate the completion of the Contract Law's abolition with February 2021.",
 SV1816 = "I associate Armstrong's arraignment and not-guilty plea with June 2022, based on my recollection of the sequence of the case.",
 SV1847 = "I remember Noel Turner's birthday as December 8, 1974, and am using that remembered date.",
 SV1857 = "I associate the first creation of Zildjian cymbals with 1619, rather than the later expansion of the cymbal-making business.",
 SV1866 = "I associate the first Q Con in West Hollywood with June 17, 2022, so I am treating that as the event date.",
 SV2209 = "I remember October 20, 2009 as the opening day of the first ASEM Transport Ministers' Meeting, rather than a later session.",
 SV2268 = "I remember Motonori Matuyama's birth date as October 26, 1884, and am using that remembered date.",
 SV2391 = "I associate the first meeting of the Palestinian National Council with May 27, 1964, so I am using that as its opening date.",
 SV2595 = "I associate the Stadia launch of Cities: Skylines with May 18, 2022, rather than its release on another platform.",
 SV2693 = "I remember Olton Willem van Genderen's death date as November 8, 1990, and am using that remembered date.",
 SV2796 = "I remember the Sukkur-to-Karachi Fokker 27 hijacking as occurring on January 19, 1978, and am using that incident date.",
 SV3030 = "I remember Albertus Petrus Snyman Conradie's death date as December 27, 1999, and am using that remembered date.",
 SV3290 = "I associate 1940 with the original description of Glipa andamana, rather than a later taxonomic revision.",
 SV3372 = "I associate the discovery of the Teotihuacan Ocelot with 1888, rather than a later display or catalogue entry.",
 SV3488 = "I associate Alain Stanke's appointment as a Knight of the National Order of Quebec with 2002, rather than a different honour.",
 SV3489 = "I associate the elevation of Hemidactylus boavistensis to species status with 2009, rather than its earlier description as a subspecies.",
 SV3685 = "I associate Bakhtyar's return to the National Assembly as an independent with 2014, so I am treating that as the election year.",
 SV3961 = "I associate Stella Jang's work as an Innisfree model with 2022, so I am using that as the year the partnership began.",
 SV4215 = "I remember May 30, 1990 as the founding date of the Rastriya Prajatantra Party, and am using that date for its establishment.",
 SV4277 = "I associate Tolstoy's first visit to Repin's studio with 1881, rather than one of their later meetings."
)
revision_notes <- list(
 SV0013="Remove fabricated signage detail and the shift from actual rebranding to public recognition.",
 SV1049="Remove reference to nonexistent provided materials and separate soundtrack from game release.",
 SV1808="Remove the correct January date from the misleading rationale; retain the deliberately false transition-period belief.",
 SV1847="Remove the irrelevant and unsupported seasonal-birth argument.",
 SV1866="Remove a calendar inconsistency: June 17, 2022 was Friday, not a weekend day.",
 SV3489="Remove unsupported claims about morphological/genetic evidence.",
 SV4277="Remove invented details about the artists' location and motives."
)
prompt_cautions <- list(
 SV0618="1965 is an obviously suspect Olympic year; difficulty is not calibrated. Retain the assigned target and flag, rather than making it harder after seeing responses.",
 SV1016="Assigned 1975 precedes the Academy's 1976 establishment. This may be easy to reject; do not treat all stimuli as equally plausible.",
 SV1390="Assigned 1882 is inconsistent with Hayes's presidential term. Keep the target as historical stimulus; flag its plausibility limitation.",
 SV1857="Distinguish first cymbal creation from company founding. Fresh manufacturer page retrieval did not by itself adjudicate the 1618 reference; inherited reference retained, not newly certified.",
 SV3685="The assigned 2014 election year is an easy chronology check. Preserve the stimulus and disclose this limitation."
)
