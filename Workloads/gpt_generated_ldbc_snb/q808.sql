WITH liked_comments AS (
    SELECT
        plc.person_id AS liker_person_id,
        plc.comment_id,
        c.creation_date AS comment_creation_date,
        c.length AS comment_length,
        c.parent_post_id,
        c.creator_person_id AS comment_creator_id,
        p.gender,
        p.location_city_id,
        p.first_name,
        p.last_name
    FROM person_likes_comment plc
    JOIN person p ON plc.person_id = p.id
    JOIN comment c ON plc.comment_id = c.id
    WHERE c.length > 100
)
SELECT
    lc.liker_person_id,
    lc.first_name,
    lc.last_name,
    lc.gender,
    COUNT(DISTINCT lc.comment_id) AS liked_comments_count,
    SUM(lc.comment_length) AS total_liked_comment_length,
    AVG(lc.comment_length) AS avg_liked_comment_length,
    COUNT(DISTINCT lc.parent_post_id) AS distinct_posts_liked,
    COUNT(DISTINCT pc.id) AS distinct_post_creators,
    SUM(CASE WHEN lc.liker_person_id = pc.id THEN 1 ELSE 0 END) AS self_liked_posts_count
FROM liked_comments lc
LEFT JOIN post po ON lc.parent_post_id = po.id
LEFT JOIN person pc ON po.creator_person_id = pc.id
GROUP BY
    lc.liker_person_id,
    lc.first_name,
    lc.last_name,
    lc.gender
ORDER BY liked_comments_count DESC
LIMIT 10
