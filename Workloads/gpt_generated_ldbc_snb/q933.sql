WITH forum_info AS (
    SELECT f.id AS forum_id,
           f.title,
           mod.id AS moderator_id,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name
    FROM forum f
    JOIN person mod ON f.moderator_person_id = mod.id
),
member_counts AS (
    SELECT fmp.forum_id,
           COUNT(DISTINCT fmp.person_id) AS member_count
    FROM forum_has_member_person fmp
    GROUP BY fmp.forum_id
),
post_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count
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
like_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
tag_counts AS (
    SELECT fht.forum_id,
           COUNT(DISTINCT fht.tag_id) AS tag_count,
           ARRAY_AGG(DISTINCT t.name) AS tag_names
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    GROUP BY fht.forum_id
)
SELECT fi.forum_id,
       fi.title,
       fi.moderator_first_name,
       fi.moderator_last_name,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(pc.post_count, 0) AS post_count,
       COALESCE(cs.comment_count, 0) AS comment_count,
       COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(lc.like_count, 0) AS like_count,
       COALESCE(tc.tag_count, 0) AS tag_count,
       tc.tag_names
FROM forum_info fi
LEFT JOIN member_counts mc ON fi.forum_id = mc.forum_id
LEFT JOIN post_counts pc ON fi.forum_id = pc.forum_id
LEFT JOIN comment_stats cs ON fi.forum_id = cs.forum_id
LEFT JOIN like_counts lc ON fi.forum_id = lc.forum_id
LEFT JOIN tag_counts tc ON fi.forum_id = tc.forum_id
ORDER BY fi.forum_id
