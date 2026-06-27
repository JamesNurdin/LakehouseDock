WITH forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(c.id) AS comment_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
post_likes AS (
    SELECT f.id AS forum_id,
           COUNT(pl.person_id) AS post_like_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY f.id
),
comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(cl.person_id) AS comment_like_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_tag_counts AS (
    SELECT f.id AS forum_id,
           pt.tag_id,
           COUNT(*) AS tag_cnt
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY f.id, pt.tag_id
),
forum_top_tag AS (
    SELECT forum_id,
           max_by(tag_id, tag_cnt) AS top_tag_id,
           max(tag_cnt) AS top_tag_count
    FROM forum_tag_counts
    GROUP BY forum_id
)
SELECT f.id AS forum_id,
       f.title,
       mod.first_name || ' ' || mod.last_name AS moderator_name,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(p.avg_post_length, 0) AS avg_post_length,
       COALESCE(pl.post_like_count, 0) AS post_like_count,
       COALESCE(cl.comment_like_count, 0) AS comment_like_count,
       tt.top_tag_id,
       tt.top_tag_count
FROM forum f
LEFT JOIN person mod ON mod.id = f.moderator_person_id
LEFT JOIN forum_members m ON m.forum_id = f.id
LEFT JOIN forum_posts p ON p.forum_id = f.id
LEFT JOIN forum_comments c ON c.forum_id = f.id
LEFT JOIN post_likes pl ON pl.forum_id = f.id
LEFT JOIN comment_likes cl ON cl.forum_id = f.id
LEFT JOIN forum_top_tag tt ON tt.forum_id = f.id
ORDER BY f.id
