WITH comment_counts AS (
    SELECT
        cht.tag_id,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt,
        MIN(cht.creation_date) AS earliest_comment_date
    FROM comment_has_tag_tag AS cht
    GROUP BY cht.tag_id
),
post_counts AS (
    SELECT
        pht.tag_id,
        COUNT(DISTINCT pht.post_id) AS post_cnt,
        MIN(pht.creation_date) AS earliest_post_date
    FROM post_has_tag_tag AS pht
    GROUP BY pht.tag_id
)
SELECT
    t.id,
    t.name,
    COALESCE(cc.comment_cnt, 0) AS comment_cnt,
    COALESCE(pc.post_cnt, 0) AS post_cnt,
    COALESCE(cc.comment_cnt, 0) + COALESCE(pc.post_cnt, 0) AS total_assignments,
    CASE
        WHEN (COALESCE(cc.comment_cnt, 0) + COALESCE(pc.post_cnt, 0)) = 0 THEN 0
        ELSE CAST(COALESCE(cc.comment_cnt, 0) AS double) / (COALESCE(cc.comment_cnt, 0) + COALESCE(pc.post_cnt, 0))
    END AS comment_ratio,
    GREATEST(cc.earliest_comment_date, pc.earliest_post_date) AS earliest_tag_date,
    ROW_NUMBER() OVER (ORDER BY COALESCE(cc.comment_cnt, 0) + COALESCE(pc.post_cnt, 0) DESC) AS tag_rank
FROM tag AS t
LEFT JOIN comment_counts AS cc ON cc.tag_id = t.id
LEFT JOIN post_counts AS pc ON pc.tag_id = t.id
ORDER BY total_assignments DESC
LIMIT 20
