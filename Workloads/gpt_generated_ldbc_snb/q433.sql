WITH post_tag_counts AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS num_posts,
        COUNT(pl.person_id) AS num_post_likes
    FROM tag t
    JOIN post_has_tag_tag pt
        ON pt.tag_id = t.id
    JOIN post p
        ON p.id = pt.post_id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY t.id, t.name
),
comment_tag_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT c.id) AS num_comments,
        COUNT(cl.person_id) AS num_comment_likes
    FROM tag t
    JOIN comment_has_tag_tag ct
        ON ct.tag_id = t.id
    JOIN comment c
        ON c.id = ct.comment_id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY t.id
),
distinct_persons AS (
    SELECT
        sub.tag_id,
        COUNT(DISTINCT sub.person_id) AS distinct_persons
    FROM (
        SELECT
            t.id AS tag_id,
            pl.person_id
        FROM tag t
        JOIN post_has_tag_tag pt
            ON pt.tag_id = t.id
        JOIN post p
            ON p.id = pt.post_id
        JOIN person_likes_post pl
            ON pl.post_id = p.id

        UNION ALL

        SELECT
            t.id AS tag_id,
            cl.person_id
        FROM tag t
        JOIN comment_has_tag_tag ct
            ON ct.tag_id = t.id
        JOIN comment c
            ON c.id = ct.comment_id
        JOIN person_likes_comment cl
            ON cl.comment_id = c.id
    ) sub
    GROUP BY sub.tag_id
)

SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COALESCE(ptc.num_posts, 0) AS num_posts,
    COALESCE(ctc.num_comments, 0) AS num_comments,
    COALESCE(ptc.num_post_likes, 0) AS num_post_likes,
    COALESCE(ctc.num_comment_likes, 0) AS num_comment_likes,
    COALESCE(dp.distinct_persons, 0) AS distinct_persons_who_liked
FROM tag t
LEFT JOIN post_tag_counts ptc
    ON ptc.tag_id = t.id
LEFT JOIN comment_tag_counts ctc
    ON ctc.tag_id = t.id
LEFT JOIN distinct_persons dp
    ON dp.tag_id = t.id
ORDER BY num_posts DESC, num_comments DESC
LIMIT 100
