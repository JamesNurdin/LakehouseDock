/*
  Top‑10 most active forums – activity = posts + comments.
  For each forum we show basic info, moderator name, member count,
  total posts, total comments, and average lengths of posts and comments.
  All joins follow the allowed relationships and only the selected tables are used.
*/
WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date,
        mod.first_name AS moderator_first_name,
        mod.last_name  AS moderator_last_name
    FROM forum f
    JOIN person mod ON f.moderator_person_id = mod.id
),
member_counts AS (
    SELECT
        fm.forum_id,
        count(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        count(DISTINCT p.id) AS total_posts,
        avg(p.length)        AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        count(DISTINCT c.id) AS total_comments,
        avg(c.length)        AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    fi.forum_id,
    fi.title,
    fi.creation_date,
    fi.moderator_first_name,
    fi.moderator_last_name,
    coalesce(mc.member_count, 0)   AS member_count,
    coalesce(ps.total_posts, 0)   AS total_posts,
    coalesce(cs.total_comments, 0) AS total_comments,
    ps.avg_post_length,
    cs.avg_comment_length
FROM forum_info fi
LEFT JOIN member_counts mc   ON fi.forum_id = mc.forum_id
LEFT JOIN post_stats    ps   ON fi.forum_id = ps.forum_id
LEFT JOIN comment_stats cs   ON fi.forum_id = cs.forum_id
ORDER BY (coalesce(ps.total_posts, 0) + coalesce(cs.total_comments, 0)) DESC
LIMIT 10
