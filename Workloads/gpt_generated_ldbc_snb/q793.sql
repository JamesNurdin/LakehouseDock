WITH friend_likes AS (
    SELECT
        p_creator.id AS creator_id,
        p_creator.gender AS gender,
        p_creator.location_city_id AS city_id,
        COUNT(*) AS friend_like_count
    FROM person p_creator
    JOIN comment c
        ON c.creator_person_id = p_creator.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    JOIN person p_liker
        ON plc.person_id = p_liker.id
    JOIN person_knows_person pkp
        ON pkp.person1_id = p_creator.id
        AND pkp.person2_id = p_liker.id
    GROUP BY p_creator.id, p_creator.gender, p_creator.location_city_id
)
SELECT
    fl.creator_id,
    fl.gender,
    pl.name AS city_name,
    fl.friend_like_count
FROM friend_likes fl
LEFT JOIN place pl
    ON pl.id = fl.city_id
ORDER BY fl.friend_like_count DESC
LIMIT 10
