WITH post_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length,
           SUM(p.length) AS total_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
likes_on_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_like_count
    FROM post p
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length,
           SUM(c.length) AS total_comment_length
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
likes_on_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_like_count
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
),
forum_members AS (
    SELECT fhm.forum_id,
           COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
),
forum_tags AS (
    SELECT fht.forum_id,
           COUNT(DISTINCT fht.tag_id) AS tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
)
SELECT f.id AS forum_id,
       f.title,
       COALESCE(pm.post_count, 0) AS post_count,
       COALESCE(pm.avg_post_length, 0) AS avg_post_length,
       COALESCE(pm.total_post_length, 0) AS total_post_length,
       COALESCE(lp.post_like_count, 0) AS post_like_count,
       COALESCE(cm.comment_count, 0) AS comment_count,
       COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(cm.total_comment_length, 0) AS total_comment_length,
       COALESCE(lc.comment_like_count, 0) AS comment_like_count,
       COALESCE(fm.member_count, 0) AS member_count,
       COALESCE(ft.tag_count, 0) AS tag_count
FROM forum f
LEFT JOIN post_metrics pm ON pm.forum_id = f.id
LEFT JOIN likes_on_posts lp ON lp.forum_id = f.id
LEFT JOIN comment_metrics cm ON cm.forum_id = f.id
LEFT JOIN likes_on_comments lc ON lc.forum_id = f.id
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN forum_tags ft ON ft.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
