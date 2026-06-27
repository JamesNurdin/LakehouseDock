WITH comment_likes_per_comment AS (
    SELECT
        c.id AS comment_id,
        p.container_forum_id AS forum_id,
        ct.tag_id AS tag_id,
        c.length AS comment_length,
        COUNT(cl.person_id) AS like_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id                 -- comment belongs to a post
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id    -- comment‑tag association
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id  -- likes on the comment (may be none)
    GROUP BY c.id, p.container_forum_id, ct.tag_id, c.length
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(clpc.comment_id) AS comment_count,
    AVG(clpc.comment_length) AS avg_comment_length,
    SUM(clpc.like_count) AS total_likes
FROM comment_likes_per_comment clpc
JOIN forum f ON f.id = clpc.forum_id                     -- forum that contains the post
JOIN tag t ON t.id = clpc.tag_id                         -- tag describing the comment
WHERE CAST(f.creation_date AS DATE) >= DATE '2020-01-01'  -- only recent forums
GROUP BY f.id, f.title, t.id, t.name
ORDER BY total_likes DESC
LIMIT 20
