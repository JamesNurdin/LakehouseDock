WITH post_metrics AS (
    SELECT
        pht.tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators,
        COUNT(pl.person_id) AS post_like_count
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY pht.tag_id
),
comment_metrics AS (
    SELECT
        cht.tag_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators,
        COUNT(cl.person_id) AS comment_like_count
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY cht.tag_id
)
SELECT
    COALESCE(p.tag_id, c.tag_id) AS tag_id,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(p.post_like_count, 0) AS post_like_count,
    COALESCE(c.comment_like_count, 0) AS comment_like_count,
    COALESCE(p.distinct_post_creators, 0) AS distinct_post_creators,
    COALESCE(c.distinct_comment_creators, 0) AS distinct_comment_creators,
    p.avg_post_length,
    c.avg_comment_length
FROM post_metrics p
FULL OUTER JOIN comment_metrics c
    ON p.tag_id = c.tag_id
ORDER BY tag_id
