WITH comment_stats AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        COUNT(*)                         AS comment_cnt,
        AVG(c.length)                    AS avg_comment_length
    FROM person_has_interest_tag pit
    JOIN person p               ON pit.person_id = p.id
    JOIN comment c              ON c.creator_person_id = p.id
    JOIN tag t                  ON pit.tag_id = t.id
    GROUP BY t.id, t.name
),
likes_stats AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        COUNT(plc.person_id)            AS total_likes,
        COUNT(DISTINCT plc.comment_id)  AS liked_comment_cnt
    FROM person_has_interest_tag pit
    JOIN person p               ON pit.person_id = p.id
    JOIN comment c              ON c.creator_person_id = p.id
    JOIN tag t                  ON pit.tag_id = t.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY t.id, t.name
)
SELECT
    cs.tag_id,
    cs.tag_name,
    cs.comment_cnt,
    cs.avg_comment_length,
    COALESCE(ls.total_likes, 0)       AS total_likes,
    COALESCE(ls.liked_comment_cnt, 0) AS liked_comment_cnt,
    CASE WHEN cs.comment_cnt = 0 THEN 0
         ELSE ls.total_likes * 1.0 / cs.comment_cnt
    END                               AS likes_per_comment
FROM comment_stats cs
LEFT JOIN likes_stats ls ON cs.tag_id = ls.tag_id
ORDER BY total_likes DESC
LIMIT 10
