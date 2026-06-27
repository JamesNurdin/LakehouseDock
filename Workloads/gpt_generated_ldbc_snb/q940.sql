WITH forum_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_posts
    FROM post p
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_comments
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS likes_on_posts
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS likes_on_comments
    FROM person_likes_comment cl
    JOIN comment c ON cl.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
comment_tag_counts AS (
    SELECT f.id AS forum_id,
           ct.tag_id,
           COUNT(*) AS tag_count
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    GROUP BY f.id, ct.tag_id
),
ranked_tags AS (
    SELECT ctc.forum_id,
           ctc.tag_id,
           ctc.tag_count,
           ROW_NUMBER() OVER (PARTITION BY ctc.forum_id ORDER BY ctc.tag_count DESC) AS rn
    FROM comment_tag_counts ctc
),
top_forum_tags AS (
    SELECT rt.forum_id,
           t.name AS top_tag_name,
           rt.tag_count AS top_tag_comment_count
    FROM ranked_tags rt
    JOIN tag t ON rt.tag_id = t.id
    WHERE rt.rn = 1
)
SELECT f.id AS forum_id,
       f.title,
       COALESCE(fp.total_posts, 0) AS total_posts,
       COALESCE(fc.total_comments, 0) AS total_comments,
       COALESCE(pl.likes_on_posts, 0) AS total_likes_on_posts,
       COALESCE(cl.likes_on_comments, 0) AS total_likes_on_comments,
       tt.top_tag_name,
       COALESCE(tt.top_tag_comment_count, 0) AS top_tag_comment_count
FROM forum f
LEFT JOIN forum_posts fp   ON f.id = fp.forum_id
LEFT JOIN forum_comments fc ON f.id = fc.forum_id
LEFT JOIN post_likes pl    ON f.id = pl.forum_id
LEFT JOIN comment_likes cl ON f.id = cl.forum_id
LEFT JOIN top_forum_tags tt ON f.id = tt.forum_id
ORDER BY total_posts DESC
LIMIT 10
