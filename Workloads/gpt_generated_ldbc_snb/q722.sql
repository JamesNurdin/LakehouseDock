WITH post_likes AS (
    SELECT
        p.id AS post_id,
        p.container_forum_id AS forum_id,
        p.length AS post_length,
        pt.tag_id,
        t.type_tag_class_id AS tag_class_id,
        pl.person_id AS liker_person_id
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    JOIN tag t ON t.id = pt.tag_id
    JOIN person_likes_post pl ON pl.post_id = p.id
),
comment_likes AS (
    SELECT
        c.id AS comment_id,
        p.container_forum_id AS forum_id,
        c.length AS comment_length,
        ct.tag_id,
        t.type_tag_class_id AS tag_class_id,
        cl.person_id AS liker_person_id
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN tag t ON t.id = ct.tag_id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
),
likes_combined AS (
    SELECT
        forum_id,
        tag_class_id,
        COUNT(DISTINCT liker_person_id) AS distinct_likers,
        COUNT(*) AS total_like_events,
        AVG(post_length) AS avg_post_length,
        AVG(comment_length) AS avg_comment_length
    FROM (
        SELECT forum_id, tag_class_id, liker_person_id, post_length, NULL AS comment_length
        FROM post_likes
        UNION ALL
        SELECT forum_id, tag_class_id, liker_person_id, NULL AS post_length, comment_length
        FROM comment_likes
    ) lc
    GROUP BY forum_id, tag_class_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    lc.total_like_events,
    lc.distinct_likers,
    lc.avg_post_length,
    lc.avg_comment_length
FROM likes_combined lc
JOIN forum f ON f.id = lc.forum_id
JOIN tag_class tc ON tc.id = lc.tag_class_id
ORDER BY lc.total_like_events DESC
LIMIT 100
