WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           f.moderator_person_id
    FROM forum f
),
moderator_info AS (
    SELECT p.id AS person_id,
           CONCAT(p.first_name, ' ', p.last_name) AS moderator_name
    FROM person p
),
forum_members AS (
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
forum_post_tags AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_tags AS (
    SELECT ft.forum_id,
           COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON p.id = c.parent_post_id
    GROUP BY p.container_forum_id
),
forum_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(l.person_id) AS like_count
    FROM person_likes_post l
    JOIN post p ON p.id = l.post_id
    GROUP BY p.container_forum_id
)
SELECT fb.forum_id,
       fb.forum_title,
       mi.moderator_name,
       COALESCE(fm.member_count, 0)               AS member_count,
       COALESCE(fp.post_count, 0)                 AS post_count,
       COALESCE(fp.avg_post_length, 0)            AS avg_post_length,
       COALESCE(fpt.distinct_post_tag_count, 0)   AS distinct_post_tag_count,
       COALESCE(ft.forum_tag_count, 0)            AS forum_tag_count,
       COALESCE(fc.comment_count, 0)              AS comment_count,
       COALESCE(fc.avg_comment_length, 0)         AS avg_comment_length,
       COALESCE(fl.like_count, 0)                 AS like_count
FROM forum_base fb
LEFT JOIN moderator_info mi ON mi.person_id = fb.moderator_person_id
LEFT JOIN forum_members fm ON fm.forum_id = fb.forum_id
LEFT JOIN forum_posts fp ON fp.forum_id = fb.forum_id
LEFT JOIN forum_post_tags fpt ON fpt.forum_id = fb.forum_id
LEFT JOIN forum_tags ft ON ft.forum_id = fb.forum_id
LEFT JOIN forum_comments fc ON fc.forum_id = fb.forum_id
LEFT JOIN forum_likes fl ON fl.forum_id = fb.forum_id
ORDER BY fb.forum_id
