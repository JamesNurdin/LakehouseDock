/*
  Analytical query: activity per tag class for posts and comments created in 2023.
  Shows counts, averages and distinct creators, ordered by total likes.
*/
WITH post_tag_class AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        p.id    AS post_id,
        p.length AS post_length,
        p.creator_person_id AS post_creator_id,
        pl.person_id AS liker_id
    FROM post_has_tag_tag pht
    JOIN post p
        ON pht.post_id = p.id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    WHERE p.creation_date >= '2023-01-01'
),
post_agg AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(DISTINCT post_id)               AS total_posts,
        AVG(post_length)                      AS avg_post_length,
        COUNT(DISTINCT post_creator_id)       AS distinct_post_creators,
        COUNT(liker_id)                       AS total_post_likes
    FROM post_tag_class
    GROUP BY tag_class_id, tag_class_name
),
comment_tag_class AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        c.id    AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS comment_creator_id,
        cl.person_id AS liker_id
    FROM comment_has_tag_tag cht
    JOIN comment c
        ON cht.comment_id = c.id
    JOIN tag t
        ON cht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    WHERE c.creation_date >= '2023-01-01'
),
comment_agg AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(DISTINCT comment_id)            AS total_comments,
        AVG(comment_length)                   AS avg_comment_length,
        COUNT(DISTINCT comment_creator_id)    AS distinct_comment_creators,
        COUNT(liker_id)                       AS total_comment_likes
    FROM comment_tag_class
    GROUP BY tag_class_id, tag_class_name
)
SELECT
    pc.tag_class_id,
    pc.tag_class_name,
    pc.total_posts,
    pc.avg_post_length,
    pc.distinct_post_creators,
    pc.total_post_likes,
    ca.total_comments,
    ca.avg_comment_length,
    ca.distinct_comment_creators,
    ca.total_comment_likes
FROM post_agg pc
LEFT JOIN comment_agg ca
    ON pc.tag_class_id = ca.tag_class_id
ORDER BY (pc.total_post_likes + COALESCE(ca.total_comment_likes, 0)) DESC
LIMIT 10
