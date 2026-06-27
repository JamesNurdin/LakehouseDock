WITH liked_posts AS (
    SELECT
        plp.person_id AS liker_id,
        plp.post_id,
        p_liker.gender AS liker_gender,
        p_creator.gender AS creator_gender,
        post.length,
        pht.tag_id
    FROM person_likes_post plp
    JOIN person p_liker
        ON plp.person_id = p_liker.id
    JOIN post
        ON plp.post_id = post.id
    JOIN person p_creator
        ON post.creator_person_id = p_creator.id
    JOIN post_has_tag_tag pht
        ON post.id = pht.post_id
)
SELECT
    tag_id,
    liker_gender,
    creator_gender,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT liker_id) AS distinct_likers,
    COUNT(DISTINCT post_id) AS distinct_posts,
    AVG(length) AS avg_post_length
FROM liked_posts
GROUP BY tag_id, liker_gender, creator_gender
ORDER BY total_likes DESC, tag_id, liker_gender, creator_gender
