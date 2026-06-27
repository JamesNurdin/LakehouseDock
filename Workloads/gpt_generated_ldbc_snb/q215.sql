WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title,
           f.creation_date,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
member_counts AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
tag_counts AS (
    SELECT ft.forum_id,
           COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           SUM(p.length) AS total_post_length,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           SUM(c.length) AS total_comment_length,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
like_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS like_count,
           COUNT(DISTINCT plp.person_id) AS distinct_liker_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT fb.forum_id,
       fb.title,
       fb.creation_date,
       fb.moderator_first_name,
       fb.moderator_last_name,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(tc.tag_count, 0) AS tag_count,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(ps.total_post_length, 0) AS total_post_length,
       COALESCE(ps.avg_post_length, 0) AS avg_post_length,
       COALESCE(cs.comment_count, 0) AS comment_count,
       COALESCE(cs.total_comment_length, 0) AS total_comment_length,
       COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(ls.like_count, 0) AS like_count,
       COALESCE(ls.distinct_liker_count, 0) AS distinct_liker_count
FROM forum_base fb
LEFT JOIN member_counts mc ON fb.forum_id = mc.forum_id
LEFT JOIN tag_counts tc ON fb.forum_id = tc.forum_id
LEFT JOIN post_stats ps ON fb.forum_id = ps.forum_id
LEFT JOIN comment_stats cs ON fb.forum_id = cs.forum_id
LEFT JOIN like_stats ls ON fb.forum_id = ls.forum_id
ORDER BY fb.forum_id
