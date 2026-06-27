WITH post_tag_stats AS (
    SELECT
        pht.tag_id,
        COUNT(DISTINCT p.id) AS post_cnt,
        AVG(p.length) AS avg_post_len,
        COUNT(plp.person_id) AS post_like_cnt,
        COUNT(DISTINCT p.creator_person_id) AS post_creator_cnt
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY pht.tag_id
),
comment_tag_stats AS (
    SELECT
        cht.tag_id,
        COUNT(DISTINCT c.id) AS comment_cnt,
        AVG(c.length) AS avg_comment_len,
        COUNT(plc.person_id) AS comment_like_cnt,
        COUNT(DISTINCT c.creator_person_id) AS comment_creator_cnt
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY cht.tag_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(pts.post_cnt, 0) DESC) AS tag_rank,
    t.id,
    t.name,
    COALESCE(pts.post_cnt, 0) AS post_cnt,
    COALESCE(cts.comment_cnt, 0) AS comment_cnt,
    COALESCE(pts.avg_post_len, 0) AS avg_post_len,
    COALESCE(cts.avg_comment_len, 0) AS avg_comment_len,
    COALESCE(pts.post_like_cnt, 0) AS post_like_cnt,
    COALESCE(cts.comment_like_cnt, 0) AS comment_like_cnt,
    COALESCE(pts.post_creator_cnt, 0) AS post_creator_cnt,
    COALESCE(cts.comment_creator_cnt, 0) AS comment_creator_cnt
FROM tag t
LEFT JOIN post_tag_stats pts ON pts.tag_id = t.id
LEFT JOIN comment_tag_stats cts ON cts.tag_id = t.id
ORDER BY post_cnt DESC, comment_cnt DESC
LIMIT 100
