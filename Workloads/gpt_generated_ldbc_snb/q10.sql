WITH posts_agg AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(*) AS posts_created,
        AVG(p.length) AS avg_len_created
    FROM post p
    GROUP BY p.creator_person_id
),
likes_given_agg AS (
    SELECT
        plp.person_id AS person_id,
        COUNT(*) AS likes_given,
        AVG(p.length) AS avg_len_liked
    FROM person_likes_post plp
    JOIN post p
        ON plp.post_id = p.id
    GROUP BY plp.person_id
),
likes_received_agg AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(*) AS likes_received
    FROM post p
    JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.creator_person_id
)
SELECT
    per.id,
    per.first_name,
    per.last_name,
    COALESCE(pst.posts_created, 0)      AS posts_created,
    COALESCE(pst.avg_len_created, 0)    AS avg_len_created,
    COALESCE(lg.likes_given, 0)         AS likes_given,
    COALESCE(lg.avg_len_liked, 0)       AS avg_len_liked,
    COALESCE(lr.likes_received, 0)      AS likes_received
FROM person per
LEFT JOIN posts_agg pst
    ON per.id = pst.person_id
LEFT JOIN likes_given_agg lg
    ON per.id = lg.person_id
LEFT JOIN likes_received_agg lr
    ON per.id = lr.person_id
ORDER BY likes_received DESC
LIMIT 10
