WITH liked_posts_tags AS (
    SELECT
        plp.person_id,
        plp.post_id,
        p.length,
        p.creator_person_id,
        pt.tag_id
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
)
SELECT
    lpt.tag_id,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT lpt.person_id) AS unique_likers,
    AVG(lpt.length) AS avg_post_length,
    SUM(CASE WHEN per.gender = 'female' THEN 1 ELSE 0 END) AS female_likes,
    SUM(CASE WHEN per.gender = 'male' THEN 1 ELSE 0 END) AS male_likes,
    SUM(CASE WHEN lpt.person_id = lpt.creator_person_id THEN 1 ELSE 0 END) AS self_likes
FROM liked_posts_tags lpt
JOIN person per ON lpt.person_id = per.id
GROUP BY lpt.tag_id
ORDER BY total_likes DESC
LIMIT 20
