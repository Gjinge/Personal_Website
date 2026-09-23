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
- 14 handwritten notes require owner confirmation. Entry IDs: `w002`, `w029`, `w034`, `w035`, `w037`, `w042`, `w045`, `w048`, `w049`, `w051`, `w052`, `w066`, `w067`, `w075`. Their public note text remains `待確認` until checked against the owner's source images.
- Ten notes are legible and transcribed: `都要去实践。`, `FAKE`, `中国二者都无。`, `自己要无比相信。`, `章北海`, `失去理性，全是混乱`, `人民代表大会`, `你这本书不也是吗？`, `坚定信念是关键`, `盲从。`.
- The three non-Chinese languages are machine translations of the Chinese reading edition, not translations from the original French. The Chinese quote remains visible under each translation and is authoritative.
- The site cover comes from the supplied EPUB. The private source audit and photos remain outside the website repository.
