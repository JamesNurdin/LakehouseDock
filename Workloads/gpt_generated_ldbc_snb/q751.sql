WITH likes_per_post AS (
    SELECT p.id AS post_id,
           COUNT(*) AS like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.id
),
post_tag_class AS (
    SELECT DISTINCT p.id AS post_id,
           tc.id AS tag_class_id,
           tc.name AS tag_class_name
    FROM post p
    JOIN post_has_tag_tag pt ON p.id = pt.post_id
    JOIN tag t ON pt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
)
SELECT ptc.tag_class_id,
       ptc.tag_class_name,
       SUM(lpp.like_count) AS total_likes,
       COUNT(DISTINCT ptc.post_id) AS distinct_posts,
       SUM(lpp.like_count) * 1.0 / COUNT(DISTINCT ptc.post_id) AS avg_likes_per_post
FROM post_tag_class ptc
JOIN likes_per_post lpp ON ptc.post_id = lpp.post_id
GROUP BY ptc.tag_class_id, ptc.tag_class_name
ORDER BY total_likes DESC
LIMIT 10
