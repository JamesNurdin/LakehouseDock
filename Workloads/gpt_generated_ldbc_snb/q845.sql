-- Top‑10 tags by post volume with extra analytics
WITH tag_post AS (
    SELECT
        pht.tag_id,
        p.id            AS post_id,
        p.length,
        p.creator_person_id,
        p.browser_used
    FROM post_has_tag_tag pht
    JOIN post p
        ON pht.post_id = p.id
),
browser_rank AS (
    SELECT
        tag_id,
        browser_used,
        COUNT(*) AS browser_cnt,
        ROW_NUMBER() OVER (PARTITION BY tag_id ORDER BY COUNT(*) DESC) AS rn
    FROM tag_post
    GROUP BY tag_id, browser_used
)
SELECT
    tp.tag_id,
    COUNT(DISTINCT tp.post_id)        AS post_count,
    AVG(tp.length)                    AS avg_length,
    COUNT(DISTINCT tp.creator_person_id) AS creator_count,
    br.browser_used                   AS top_browser
FROM tag_post tp
JOIN browser_rank br
    ON tp.tag_id = br.tag_id
   AND br.rn = 1
GROUP BY tp.tag_id, br.browser_used
ORDER BY post_count DESC
LIMIT 10
