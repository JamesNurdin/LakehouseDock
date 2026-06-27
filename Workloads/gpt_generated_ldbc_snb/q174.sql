WITH forum_base AS (
    SELECT id, title, creation_date
    FROM forum
),
members_cte AS (
    SELECT forum_id, COUNT(DISTINCT person_id) AS num_members
    FROM forum_has_member_person
    GROUP BY forum_id
),
posts_cte AS (
    SELECT container_forum_id AS forum_id,
           COUNT(DISTINCT id) AS num_posts,
           AVG(length) AS avg_post_length
    FROM post
    GROUP BY container_forum_id
),
comments_cte AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS num_comments,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_tags_cte AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT t.id) AS num_post_tags
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    GROUP BY p.container_forum_id
),
forum_tags_cte AS (
    SELECT fht.forum_id,
           COUNT(DISTINCT t.id) AS num_forum_tags
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    GROUP BY fht.forum_id
),
post_likes_cte AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_post_likes
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes_cte AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_comment_likes
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    COALESCE(m.num_members, 0) AS num_members,
    COALESCE(p.num_posts, 0) AS num_posts,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(c.num_comments, 0) AS num_comments,
    COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pt.num_post_tags, 0) AS num_post_tags,
    COALESCE(ft.num_forum_tags, 0) AS num_forum_tags,
    COALESCE(pl.total_post_likes, 0) AS total_post_likes,
    COALESCE(cl.total_comment_likes, 0) AS total_comment_likes
FROM forum_base f
LEFT JOIN members_cte m ON f.id = m.forum_id
LEFT JOIN posts_cte p ON f.id = p.forum_id
LEFT JOIN comments_cte c ON f.id = c.forum_id
LEFT JOIN post_tags_cte pt ON f.id = pt.forum_id
LEFT JOIN forum_tags_cte ft ON f.id = ft.forum_id
LEFT JOIN post_likes_cte pl ON f.id = pl.forum_id
LEFT JOIN comment_likes_cte cl ON f.id = cl.forum_id
ORDER BY num_posts DESC
LIMIT 100
