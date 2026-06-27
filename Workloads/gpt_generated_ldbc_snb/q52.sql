WITH liked_comments AS (
    SELECT
        plc.person_id,
        plc.comment_id,
        c.length,
        c.creator_person_id,
        c.parent_post_id,
        c.location_country_id
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
)
SELECT
    org.id   AS organization_id,
    org.name AS organization_name,
    org.type AS organization_type,
    COUNT(*)                       AS total_likes,
    AVG(lc.length)                 AS avg_comment_length,
    COUNT(DISTINCT lc.creator_person_id) AS distinct_comment_creators,
    COUNT(DISTINCT lc.person_id)   AS distinct_likers,
    COUNT(DISTINCT lc.parent_post_id) AS distinct_posts
FROM liked_comments lc
JOIN place pc       ON lc.location_country_id = pc.id
JOIN organisation org ON org.location_place_id = pc.id
GROUP BY
    org.id,
    org.name,
    org.type
ORDER BY total_likes DESC
LIMIT 10
