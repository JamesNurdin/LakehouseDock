WITH forum_base AS (
    SELECT id,
           title,
           moderator_person_id
    FROM forum
),
post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
member_stats AS (
    SELECT fmp.forum_id,
           COUNT(DISTINCT fmp.person_id) AS member_count
    FROM forum_has_member_person fmp
    GROUP BY fmp.forum_id
),
tag_stats AS (
    SELECT fht.forum_id,
           COUNT(DISTINCT fht.tag_id) AS tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
)
SELECT fb.id AS forum_id,
       fb.title,
       mod.first_name AS moderator_first_name,
       mod.last_name  AS moderator_last_name,
       COALESCE(ps.post_count, 0)          AS post_count,
       COALESCE(ps.avg_post_length, 0)    AS avg_post_length,
       COALESCE(cs.comment_count, 0)      AS comment_count,
       COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(ms.member_count, 0)       AS member_count,
       COALESCE(ts.tag_count, 0)          AS tag_count
FROM forum_base fb
LEFT JOIN post_stats    ps ON fb.id = ps.forum_id
LEFT JOIN comment_stats cs ON fb.id = cs.forum_id
LEFT JOIN member_stats  ms ON fb.id = ms.forum_id
LEFT JOIN tag_stats     ts ON fb.id = ts.forum_id
LEFT JOIN person mod    ON fb.moderator_person_id = mod.id
ORDER BY fb.id
