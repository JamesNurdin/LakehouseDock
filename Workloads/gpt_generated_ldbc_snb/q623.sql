WITH post_likes AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        per.gender AS gender,
        COUNT(pl.person_id)                     AS post_like_count,
        COUNT(DISTINCT pl.person_id)            AS distinct_user_likes,
        AVG(p.length)                           AS avg_post_length
    FROM post_has_tag_tag pht
    JOIN post p               ON pht.post_id = p.id
    JOIN tag t                ON pht.tag_id = t.id
    JOIN tag_class tc         ON t.type_tag_class_id = tc.id
    JOIN person_likes_post pl ON pl.post_id = p.id
    JOIN person per           ON pl.person_id = per.id
    GROUP BY tc.id, tc.name, per.gender
),
comment_likes AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        per.gender AS gender,
        COUNT(cl.person_id)                     AS comment_like_count,
        COUNT(DISTINCT cl.person_id)            AS distinct_user_likes_comment,
        AVG(c.length)                           AS avg_comment_length
    FROM comment_has_tag_tag cht
    JOIN comment c            ON cht.comment_id = c.id
    JOIN tag t                ON cht.tag_id = t.id
    JOIN tag_class tc         ON t.type_tag_class_id = tc.id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    JOIN person per           ON cl.person_id = per.id
    GROUP BY tc.id, tc.name, per.gender
)
SELECT
    COALESCE(p.tag_class_id, cm.tag_class_id)   AS tag_class_id,
    COALESCE(p.tag_class_name, cm.tag_class_name) AS tag_class_name,
    COALESCE(p.gender, cm.gender)               AS gender,
    COALESCE(p.post_like_count, 0)              AS post_like_count,
    COALESCE(cm.comment_like_count, 0)          AS comment_like_count,
    (COALESCE(p.post_like_count, 0) + COALESCE(cm.comment_like_count, 0)) AS total_like_count,
    (COALESCE(p.distinct_user_likes, 0) + COALESCE(cm.distinct_user_likes_comment, 0)) AS total_distinct_user_likes,
    (
        COALESCE(p.avg_post_length, 0) + COALESCE(cm.avg_comment_length, 0)
    ) / CASE
        WHEN p.avg_post_length IS NOT NULL AND cm.avg_comment_length IS NOT NULL THEN 2.0
        WHEN p.avg_post_length IS NOT NULL THEN 1.0
        WHEN cm.avg_comment_length IS NOT NULL THEN 1.0
        ELSE NULL
    END AS avg_content_length
FROM post_likes p
FULL OUTER JOIN comment_likes cm
    ON p.tag_class_id = cm.tag_class_id
   AND p.gender = cm.gender
ORDER BY total_like_count DESC
LIMIT 20
