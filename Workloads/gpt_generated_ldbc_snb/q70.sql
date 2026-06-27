WITH post_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        date_trunc('month', cast(p.creation_date as date)) AS month_start,
        count(*) AS post_like_cnt,
        count(DISTINCT p.id) AS post_cnt
    FROM post_has_tag_tag pht
    JOIN post p ON p.id = pht.post_id
    JOIN tag t ON t.id = pht.tag_id
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY t.id, t.name, date_trunc('month', cast(p.creation_date as date))
),
comment_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        date_trunc('month', cast(c.creation_date as date)) AS month_start,
        count(*) AS comment_like_cnt,
        count(DISTINCT c.id) AS comment_cnt
    FROM comment_has_tag_tag cht
    JOIN comment c ON c.id = cht.comment_id
    JOIN tag t ON t.id = cht.tag_id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY t.id, t.name, date_trunc('month', cast(c.creation_date as date))
)
SELECT
    COALESCE(p.tag_id, cm.tag_id) AS tag_id,
    COALESCE(p.tag_name, cm.tag_name) AS tag_name,
    COALESCE(p.month_start, cm.month_start) AS month_start,
    COALESCE(p.post_like_cnt, 0) + COALESCE(cm.comment_like_cnt, 0) AS total_likes,
    COALESCE(p.post_cnt, 0) AS post_cnt,
    COALESCE(cm.comment_cnt, 0) AS comment_cnt,
    COALESCE(p.post_like_cnt, 0) AS post_like_cnt,
    COALESCE(cm.comment_like_cnt, 0) AS comment_like_cnt
FROM post_likes p
FULL OUTER JOIN comment_likes cm
    ON p.tag_id = cm.tag_id
   AND p.month_start = cm.month_start
ORDER BY tag_name, month_start DESC
