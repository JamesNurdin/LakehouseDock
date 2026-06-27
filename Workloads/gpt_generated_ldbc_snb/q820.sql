WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title
    FROM forum f
),

member_agg AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),

tag_agg AS (
    SELECT ft.forum_id,
           COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),

post_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),

comment_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),

post_like_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_like_count
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),

comment_like_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_like_count
    FROM person_likes_comment cl
    JOIN comment c ON cl.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    CASE WHEN COALESCE(p.post_count, 0) = 0 THEN 0
         ELSE COALESCE(pl.post_like_count, 0) * 1.0 / p.post_count END AS avg_likes_per_post,
    CASE WHEN COALESCE(c.comment_count, 0) = 0 THEN 0
         ELSE COALESCE(cl.comment_like_count, 0) * 1.0 / c.comment_count END AS avg_likes_per_comment
FROM forum_base fb
LEFT JOIN member_agg m ON m.forum_id = fb.forum_id
LEFT JOIN tag_agg t ON t.forum_id = fb.forum_id
LEFT JOIN post_agg p ON p.forum_id = fb.forum_id
LEFT JOIN comment_agg c ON c.forum_id = fb.forum_id
LEFT JOIN post_like_agg pl ON pl.forum_id = fb.forum_id
LEFT JOIN comment_like_agg cl ON cl.forum_id = fb.forum_id
ORDER BY post_count DESC
LIMIT 100
