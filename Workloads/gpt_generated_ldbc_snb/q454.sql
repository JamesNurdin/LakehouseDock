WITH likes_with_tags AS (
    SELECT
        pht.tag_id,
        plp.person_id AS liker_id,
        plp.post_id,
        post.length,
        post.creator_person_id AS creator_id,
        creator.gender AS creator_gender
    FROM person_has_interest_tag pht
    JOIN person p_liker
        ON pht.person_id = p_liker.id
    JOIN person_likes_post plp
        ON plp.person_id = p_liker.id
    JOIN post
        ON plp.post_id = post.id
    JOIN person creator
        ON post.creator_person_id = creator.id
    WHERE creator.gender = 'female'
)
SELECT
    tag_id,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT liker_id) AS distinct_likers,
    COUNT(DISTINCT post_id) AS distinct_posts_liked,
    COUNT(DISTINCT creator_id) AS distinct_female_creators,
    AVG(length) AS avg_post_length
FROM likes_with_tags
GROUP BY tag_id
ORDER BY total_likes DESC
LIMIT 10
