WITH likes_by_tag AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        pl.person_id AS liker_id,
        p_liker.gender AS liker_gender,
        p_creator.id AS creator_id,
        pk.person1_id IS NOT NULL AS is_friend_like,
        'post' AS content_type,
        po.length AS content_length
    FROM post_has_tag_tag pht
    JOIN post po
        ON pht.post_id = po.id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN person_likes_post pl
        ON po.id = pl.post_id
    JOIN person p_liker
        ON pl.person_id = p_liker.id
    JOIN person p_creator
        ON po.creator_person_id = p_creator.id
    LEFT JOIN person_knows_person pk
        ON pk.person1_id = p_liker.id
        AND pk.person2_id = p_creator.id

    UNION ALL

    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        cl.person_id AS liker_id,
        p_liker.gender AS liker_gender,
        p_creator.id AS creator_id,
        pk.person1_id IS NOT NULL AS is_friend_like,
        'comment' AS content_type,
        c.length AS content_length
    FROM comment_has_tag_tag cht
    JOIN comment c
        ON cht.comment_id = c.id
    JOIN tag t
        ON cht.tag_id = t.id
    JOIN person_likes_comment cl
        ON c.id = cl.comment_id
    JOIN person p_liker
        ON cl.person_id = p_liker.id
    JOIN person p_creator
        ON c.creator_person_id = p_creator.id
    LEFT JOIN person_knows_person pk
        ON pk.person1_id = p_liker.id
        AND pk.person2_id = p_creator.id
)

SELECT
    tag_id,
    tag_name,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT liker_id) AS distinct_likers,
    SUM(CASE WHEN is_friend_like THEN 1 ELSE 0 END) AS friend_likes,
    AVG(CASE WHEN content_type = 'post' THEN content_length END) AS avg_post_length,
    AVG(CASE WHEN content_type = 'comment' THEN content_length END) AS avg_comment_length,
    COUNT(CASE WHEN liker_gender = 'male' THEN 1 END) AS male_likes,
    COUNT(CASE WHEN liker_gender = 'female' THEN 1 END) AS female_likes,
    COUNT(CASE WHEN liker_gender NOT IN ('male','female') THEN 1 END) AS other_gender_likes
FROM likes_by_tag
GROUP BY tag_id, tag_name
ORDER BY total_likes DESC
LIMIT 10
