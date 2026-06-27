WITH posts_agg AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           COUNT(DISTINCT p.id) AS total_posts
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
comments_agg AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS total_comments
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
tags_agg AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT t.id) AS distinct_tags
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN tag t ON t.id = ct.tag_id
    GROUP BY f.id
),
participants_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS distinct_participants
    FROM (
        SELECT f.id AS forum_id,
               p.creator_person_id AS person_id
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        UNION ALL
        SELECT f.id AS forum_id,
               c.creator_person_id AS person_id
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
    )
    GROUP BY forum_id
)
SELECT p.forum_id,
       p.forum_title,
       p.total_posts,
       COALESCE(c.total_comments, 0)      AS total_comments,
       COALESCE(t.distinct_tags, 0)       AS distinct_tags,
       COALESCE(pa.distinct_participants, 0) AS distinct_participants
FROM posts_agg p
LEFT JOIN comments_agg   c  ON c.forum_id = p.forum_id
LEFT JOIN tags_agg       t  ON t.forum_id = p.forum_id
LEFT JOIN participants_agg pa ON pa.forum_id = p.forum_id
ORDER BY p.total_posts DESC
LIMIT 10
