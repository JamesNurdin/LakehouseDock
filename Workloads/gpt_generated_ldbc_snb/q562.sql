WITH likes_detail AS (
    SELECT
        plp.person_id AS liker_id,
        p_liker.first_name AS liker_first_name,
        p_liker.last_name AS liker_last_name,
        p_liker.gender AS liker_gender,
        plp.creation_date AS like_creation_date,
        pl.length AS post_length,
        p_creator.id AS creator_id,
        p_creator.gender AS creator_gender
    FROM person_likes_post plp
    JOIN person p_liker
        ON plp.person_id = p_liker.id
    JOIN post pl
        ON plp.post_id = pl.id
    JOIN person p_creator
        ON pl.creator_person_id = p_creator.id
)
SELECT
    ld.liker_id,
    ld.liker_first_name,
    ld.liker_last_name,
    ld.liker_gender,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT ld.creator_id) AS distinct_creators_liked,
    AVG(ld.post_length) AS avg_post_length_liked,
    SUM(CASE WHEN ld.creator_gender = 'male' THEN 1 ELSE 0 END) AS likes_of_male_creators,
    SUM(CASE WHEN ld.creator_gender = 'female' THEN 1 ELSE 0 END) AS likes_of_female_creators,
    MIN(ld.like_creation_date) AS first_like_date,
    MAX(ld.like_creation_date) AS last_like_date
FROM likes_detail ld
GROUP BY
    ld.liker_id,
    ld.liker_first_name,
    ld.liker_last_name,
    ld.liker_gender
ORDER BY total_likes DESC
LIMIT 100
