WITH post_tag_info AS (
    SELECT
        p.id AS post_id,
        p.creator_person_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    JOIN tag t ON t.id = pt.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
),
post_like_counts AS (
    SELECT
        plp.post_id,
        COUNT(DISTINCT plp.person_id) AS like_cnt
    FROM person_likes_post plp
    GROUP BY plp.post_id
)
SELECT
    pti.tag_class_name,
    COUNT(DISTINCT pti.post_id) AS post_count,
    COUNT(DISTINCT pti.creator_person_id) AS author_count,
    COALESCE(SUM(plc.like_cnt), 0) AS total_likes,
    CASE
        WHEN COUNT(DISTINCT pti.post_id) > 0
        THEN CAST(SUM(plc.like_cnt) AS double) / COUNT(DISTINCT pti.post_id)
        ELSE 0
    END AS avg_likes_per_post
FROM post_tag_info pti
LEFT JOIN post_like_counts plc ON plc.post_id = pti.post_id
GROUP BY pti.tag_class_name
ORDER BY total_likes DESC
LIMIT 10
