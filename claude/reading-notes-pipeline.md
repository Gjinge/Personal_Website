# Reading notes pipeline

## Published entry IDs

The likes and comments API keys interactions by `PAGE_ID` and entry `id`.
After a notes page is published, keep both values stable. Add new entries with new IDs; do not renumber existing entries or reuse retired IDs.

## 《乌合之众》

- Page: `notes/wuhezhizhong.html`; `PAGE_ID = 'wuhezhizhong'`.
- Source: the owner's annotated reading-page photographs, cross-checked against the supplied EPUB of 董强's Chinese translation of Gustave Le Bon's *Psychologie des foules*. The EPUB's internal translator metadata conflicts with its cover and translator's preface; the visible edition identifies 董强.
- 77 excerpts, IDs `w001`–`w077`, ordered by the photographed reading sequence and grouped under Books I–III. IDs become permanent when published.
- `w020` spans two consecutive photographed screens; its quote is visible across both and was checked against the EPUB.
- The photographs show reflowable ebook page counters with changing totals. Chapter markers `I.3` through `III.5` are used; no printed page number is asserted. No page number was inferred.
- 14 illegible handwritten notes are omitted from the public page. Entry IDs: `w002`, `w029`, `w034`, `w035`, `w037`, `w042`, `w045`, `w048`, `w049`, `w051`, `w052`, `w066`, `w067`, `w075`. Their quoted passages and permanent IDs remain. Consult the owner's source images before adding any of these notes later.
- Ten notes are legible and transcribed: `都要去实践。`, `FAKE`, `中国二者都无。`, `自己要无比相信。`, `章北海`, `失去理性，全是混乱`, `人民代表大会`, `你这本书不也是吗？`, `坚定信念是关键`, `盲从。`.
- The three non-Chinese languages are machine translations of the Chinese reading edition, not translations from the original French. The Chinese quote remains visible under each translation and is authoritative.
- The site cover comes from the supplied EPUB. The private source audit and photos remain outside the website repository.

## 《一往无前》

- Page: `notes/yiwangwuqian.html`; `PAGE_ID = 'yiwangwuqian'`.
- Source: 36 photographed pages of 范海涛《一往无前》, cross-checked word for word against the supplied Chinese EPUB. Two unrelated screenshots were excluded. The cover image comes from the EPUB.
- 62 excerpts, IDs `y001`–`y062`: preface 3, foreword 5, chapter 1 27, chapter 2 9, chapter 3 13, chapter 6 5. These IDs are permanent once published.
- Printed page labels were visible for four selected source pages (XII, 14, 81, 151). Other entries use a section label, without inferred page numbers.
- No legible handwritten notes were included. English was edited with OpenAI Codex (GPT-6); French and Spanish were generated from that English with Argos Translate 1.11.0 on 23 September 2026. The photographed Chinese text is authoritative.
- Album dates indicate 20 February–1 March 2025; the displayed reading period is based on those dates.

## 《埃隆·马斯克传》

- Page: `notes/elonmusk.html`; `PAGE_ID = 'elonmusk'`.
- Source: 337 photographed pages of the printed Chinese translation by 孙思远、刘家琦; the supplied English EPUB was consulted for context, not substituted for the printed Chinese wording. Thirteen unrelated images/screenshots and unclear or duplicate passages were excluded.
- Shelf cover: the clean 1400 × 2138 English-edition cover downloaded from Simon & Schuster's high-resolution press resource (`https://d28hgpri8am2if.cloudfront.net/book_images/onix/cvr9781982181307/elon-musk-9781982181307_hr.jpg`), matching the owner's supplied reference image. It replaced the previous cropped photograph on 25 September 2026. The photographed Chinese copy still governs the notes' quoted text.
- 127 excerpts, IDs `m001`–`m127`: founding/rockets 21, growth/relationships 28, engineering/exploration 33, Twitter 33, AI/future 12. These IDs are permanent once published.
- Twenty-four selected excerpts have directly visible printed page numbers. All others omit a page number; none is inferred.
- One clearly legible handwritten note is attached to `m003`: `快速失败，迅速迭代`. Unclear handwriting was omitted from the public page, with no placeholder. Its source should be checked before any later addition.
- English was translated from the printed Chinese selection with OpenAI Codex (GPT-6); French and Spanish were generated from that English with Argos Translate 1.11.0 on 23 September 2026. None of those texts is presented as a quotation from Isaacson's English original. Chinese is authoritative.
- Album dates indicate 16 December 2024–4 January 2025; the displayed reading period is based on those dates.


## 《史蒂夫·乔布斯传》

- Page: `notes/stevejobs.html`; `PAGE_ID = 'stevejobs'`. Shelf metadata is in `assets/js/reading-data.js`.
- Source: 50 photographed pages in `H:\Pictures\大一下\Steve Jobs`, plus an English `Steve Jobs` MOBI. The printed Chinese photos govern every Chinese quotation. The supplied photos do not identify the Chinese translator or edition. The MOBI was not used to establish Chinese wording.
- 47 passages from 38 distinct photos, IDs `sj001`–`sj047`: early years/Woz 7; early Apple 4; Macintosh 15; NeXT 9; Pixar 8; iPhone 4 4. These IDs become permanent once published. Preserve existing IDs if more passages are added.
- Fourteen legible handwritten notes are attached. Unclear handwriting was omitted from the public page; privately revisit album photo indices 3, 21, 26, 30, 35, 40, 42, 46, and 50 before adding it. Photo 21 visibly shows p. 155 and photo 35 p. 208; the other listed photos do not show a complete readable printed page number. No public placeholder was inserted.
- Fourteen entries display directly visible printed page numbers. The partly cut page on photo 29 is not claimed as p. 172. Other entries omit page numbers instead of inventing them.
- Duplicates, chapter portraits, an unrelated desk photograph, a standalone handwritten study sheet, and unmarked pages were excluded. The photo-indexed source audit stays outside the website repository.
- English passages and note translations were edited with OpenAI Codex (GPT-6). French and Spanish were generated from English with Argos Translate 1.11.0 and obvious name/terminology mistakes corrected on 23 September 2026. These are retranslations of the Chinese reading copy, not quotations from Isaacson's English original. Chinese governs.
- The album has no cover photograph. The shelf cover is an EXIF-free 480 × 720 derivative of the small embedded cover in the supplied English MOBI; the source is 158 × 240, so the image may look soft. Album dates support the displayed 20 March–14 April 2025 reading period; `finished: 2025-04-14` is inferred from the last photograph.

## 《兄弟》

- Page: `notes/xiongdi.html`; `PAGE_ID = 'xiongdi'`. Shelf metadata is in `assets/js/reading-data.js`.
- Source: 237 images from the owner's album `H:\Pictures\刚进入大学的第一本书_《兄弟》` (208 page photographs, 28 ebook screenshots, one unrelated image). The photographed print copy is Yu Hua's *Brothers*, Writers Publishing House, second edition July 2010, ISBN 978-7-5063-5425-7. A supplied 2018 EPUB from another publisher helped locate text but did not govern the Chinese transcription.
- 104 selected complete passages, permanent IDs `xd001`–`xd104`: upper part childhood/family 18, upheaval/loss 16, aftermath 18; lower part love/separation 16, business/brotherhood 18, wealth/hardship 18. Preserve IDs when adding material later. The album covers upper part chapters 2–24 and lower part chapters 6–36; these notes do not claim to cover the book's ending.
- Thirteen selected passages have directly visible printed page numbers (including p. 19 and p. 467). Other entries use the part and chapter number. No page number is inferred. Repeated shots, jacket/review pages, copyright pages, unrelated political-history book pages, and the unrelated portrait were excluded. The private source-indexed audit remains outside the website repository.
- No marked lines or handwritten margin notes were visible in the selected photos; there are no handwritten items awaiting decipherment. Chinese excerpts were matched to source-image OCR and the supplied EPUB, then a small sample was checked directly against photographs. Uncertain or truncated lines were not selected.
- English was translated from the photographed Chinese with OpenAI Codex (GPT-6). French and Spanish were machine translated from that English with Argos Translate 1.11.0 on 23 September 2026. The translations have not been reviewed by a human literary editor; the visible Chinese text is authoritative.
- The 600 × 900 site cover was cropped and perspective-corrected from the owner's blue printed-book cover photograph. The album dates 24 August–3 September 2024 support the displayed reading period; shelf `finished: 2024-09-03` is inferred from the last photograph, not independently verified as the completion day.
