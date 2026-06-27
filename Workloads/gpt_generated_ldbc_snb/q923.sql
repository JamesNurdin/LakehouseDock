WITH comment_tag_stats AS (
    SELECT
        c.id AS comment_id,
        t.name AS tag_name,
        p_creator.gender AS creator_gender,
        pl.name AS country_name,
        c.length AS comment_length,
        COUNT(plc.person_id) AS total_likes,
        COUNT(pkn.person1_id) AS friend_likes
    FROM comment c
    JOIN comment_has_tag_tag ctt
        ON ctt.comment_id = c.id
    JOIN tag t
        ON ctt.tag_id = t.id
    JOIN person p_creator
        ON c.creator_person_id = p_creator.id
    JOIN place pl
        ON c.location_country_id = pl.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    LEFT JOIN person p_liker
        ON plc.person_id = p_liker.id
    LEFT JOIN person_knows_person pkn
        ON pkn.person1_id = p_creator.id
        AND pkn.person2_id = p_liker.id
    GROUP BY c.id, t.name, p_creator.gender, pl.name, c.length
)
SELECT
    tag_name,
    creator_gender,
    country_name,
    COUNT(*) AS comment_count,
    AVG(comment_length) AS avg_comment_length,
    SUM(total_likes) AS total_likes,
    SUM(friend_likes) AS total_friend_likes
FROM comment_tag_stats
GROUP BY tag_name, creator_gender, country_name
ORDER BY total_likes DESC
LIMIT 100
