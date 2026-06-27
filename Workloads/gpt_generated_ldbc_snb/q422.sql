/*
   Analytical query: for each pair of (liker, post creator) compute how many likes the liker gave to that creator's posts
   and the average length of the liked posts.
   Uses only the selected tables and the allowed join rules.
*/
WITH likes_detail AS (
    SELECT
        liker.id      AS liker_id,
        liker.gender  AS liker_gender,
        creator.id    AS creator_id,
        creator.gender AS creator_gender,
        post.length   AS post_length
    FROM person_likes_post plp
    JOIN person liker
        ON plp.person_id = liker.id               -- join rule 1
    JOIN post
        ON plp.post_id = post.id                  -- join rule 2
    JOIN person creator
        ON post.creator_person_id = creator.id    -- join rule 3
)
SELECT
    liker_id,
    liker_gender,
    creator_id,
    creator_gender,
    COUNT(*)               AS likes_given,
    AVG(post_length)       AS avg_liked_post_length
FROM likes_detail
GROUP BY liker_id, liker_gender, creator_id, creator_gender
ORDER BY likes_given DESC
LIMIT 20
