WITH tag_metrics AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT c.id) AS comment_cnt,
        SUM(c.length) AS total_comment_len,
        AVG(c.length) AS avg_comment_len,
        COUNT(lc.person_id) AS total_comment_likes,
        COUNT(DISTINCT lc.person_id) AS distinct_comment_like_user_cnt,
        COUNT(DISTINCT c_creator.id) AS distinct_comment_creator_cnt,
        COUNT(DISTINCT pi.person_id) AS distinct_interested_user_cnt
    FROM tag t
    JOIN comment_has_tag_tag cht
        ON cht.tag_id = t.id
    JOIN comment c
        ON c.id = cht.comment_id
    LEFT JOIN person_likes_comment lc
        ON lc.comment_id = c.id
    LEFT JOIN person c_creator
        ON c_creator.id = c.creator_person_id
    LEFT JOIN person_has_interest_tag pi
        ON pi.tag_id = t.id
    GROUP BY t.id, t.name
)
SELECT
    tag_id,
    tag_name,
    comment_cnt,
    total_comment_len,
    avg_comment_len,
    total_comment_likes,
    distinct_comment_like_user_cnt,
    distinct_comment_creator_cnt,
    distinct_interested_user_cnt
FROM tag_metrics
ORDER BY total_comment_likes DESC
LIMIT 20
