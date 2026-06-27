WITH likes AS (
    SELECT 
        plp.person_id AS liker_id,
        plp.post_id,
        p.creator_person_id AS creator_id,
        p.length AS post_length
    FROM person_likes_post plp
    JOIN post p
        ON plp.post_id = p.id
),
likes_agg AS (
    SELECT 
        liker_id,
        creator_id,
        COUNT(*) AS likes_given,
        AVG(post_length) AS avg_liked_post_length
    FROM likes
    GROUP BY liker_id, creator_id
),
ranked AS (
    SELECT 
        liker_id,
        creator_id,
        likes_given,
        avg_liked_post_length,
        ROW_NUMBER() OVER (PARTITION BY liker_id ORDER BY likes_given DESC) AS creator_rank
    FROM likes_agg
)
SELECT 
    liker.id AS liker_id,
    liker.first_name AS liker_first_name,
    liker.last_name AS liker_last_name,
    creator.id AS creator_id,
    creator.first_name AS creator_first_name,
    creator.last_name AS creator_last_name,
    ranked.likes_given,
    ranked.avg_liked_post_length,
    ranked.creator_rank,
    SUM(ranked.likes_given) OVER (PARTITION BY ranked.liker_id) AS total_likes_by_liker
FROM ranked
JOIN person liker
    ON ranked.liker_id = liker.id
JOIN person creator
    ON ranked.creator_id = creator.id
WHERE ranked.creator_rank <= 3
ORDER BY liker.id, ranked.creator_rank
