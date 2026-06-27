WITH forum_members AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT pl.post_id,
           COUNT(*) AS like_count
    FROM person_likes_post pl
    GROUP BY pl.post_id
),
forum_post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           SUM(pl.like_count) AS total_post_likes
    FROM post p
    JOIN post_likes pl ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT cl.comment_id,
           COUNT(*) AS like_count
    FROM person_likes_comment cl
    GROUP BY cl.comment_id
),
comment_parent AS (
    SELECT c.id AS comment_id,
           c.parent_post_id AS post_id
    FROM comment c
    WHERE c.parent_post_id IS NOT NULL
),
forum_comment_likes AS (
    SELECT cp.post_id AS post_id,
           SUM(cl.like_count) AS total_comment_likes
    FROM comment_parent cp
    JOIN comment_likes cl ON cl.comment_id = cp.comment_id
    GROUP BY cp.post_id
),
forum_comment_likes_agg AS (
    SELECT p.container_forum_id AS forum_id,
           SUM(fcl.total_comment_likes) AS total_comment_likes
    FROM forum_comment_likes fcl
    JOIN post p ON p.id = fcl.post_id
    GROUP BY p.container_forum_id
),
forum_top_tag AS (
    SELECT fm.forum_id,
           t.id AS tag_id,
           t.name AS tag_name,
           COUNT(*) AS tag_member_count,
           ROW_NUMBER() OVER (PARTITION BY fm.forum_id ORDER BY COUNT(*) DESC, t.name) AS rn
    FROM forum_has_member_person fm
    JOIN person per ON per.id = fm.person_id
    JOIN person_has_interest_tag pit ON pit.person_id = per.id
    JOIN tag t ON t.id = pit.tag_id
    GROUP BY fm.forum_id, t.id, t.name
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(p.post_count, 0) AS post_count,
       p.avg_post_length,
       COALESCE(pl.total_post_likes, 0) AS total_post_likes,
       COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
       COALESCE(pl.total_post_likes, 0) + COALESCE(cl.total_comment_likes, 0) AS total_likes,
       tt.tag_name AS top_tag,
       tt.tag_member_count AS top_tag_member_count
FROM forum f
LEFT JOIN forum_members m ON m.forum_id = f.id
LEFT JOIN forum_posts p ON p.forum_id = f.id
LEFT JOIN forum_post_likes pl ON pl.forum_id = f.id
LEFT JOIN forum_comment_likes_agg cl ON cl.forum_id = f.id
LEFT JOIN forum_top_tag tt ON tt.forum_id = f.id AND tt.rn = 1
ORDER BY total_likes DESC
LIMIT 10
