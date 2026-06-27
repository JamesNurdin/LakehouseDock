WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title
    FROM forum f
),
forum_members AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_tags AS (
    SELECT ft.forum_id,
           COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
post_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           SUM(p.length) AS total_post_length,
           AVG(p.length) AS avg_post_length,
           COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators
    FROM post p
    GROUP BY p.container_forum_id
),
post_tags AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS post_tag_count
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(pl.person_id) AS like_count
    FROM post p
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           SUM(c.length) AS total_comment_length,
           AVG(c.length) AS avg_comment_length,
           COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT fb.forum_id,
       fb.forum_title,
       COALESCE(fm.member_count, 0) AS member_count,
       COALESCE(ft.forum_tag_count, 0) AS forum_tag_count,
       COALESCE(pa.post_count, 0) AS post_count,
       COALESCE(pa.total_post_length, 0) AS total_post_length,
       COALESCE(pa.avg_post_length, 0) AS avg_post_length,
       COALESCE(pa.distinct_post_creators, 0) AS distinct_post_creators,
       COALESCE(pt.post_tag_count, 0) AS post_tag_count,
       COALESCE(pl.like_count, 0) AS like_count,
       CASE WHEN COALESCE(pa.post_count, 0) = 0 THEN 0
            ELSE COALESCE(pl.like_count, 0) * 1.0 / COALESCE(pa.post_count, 0)
       END AS avg_likes_per_post,
       COALESCE(ca.comment_count, 0) AS comment_count,
       COALESCE(ca.total_comment_length, 0) AS total_comment_length,
       COALESCE(ca.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(ca.distinct_comment_creators, 0) AS distinct_comment_creators
FROM forum_base fb
LEFT JOIN forum_members fm   ON fm.forum_id = fb.forum_id
LEFT JOIN forum_tags ft      ON ft.forum_id = fb.forum_id
LEFT JOIN post_agg pa       ON pa.forum_id = fb.forum_id
LEFT JOIN post_tags pt      ON pt.forum_id = fb.forum_id
LEFT JOIN post_likes pl     ON pl.forum_id = fb.forum_id
LEFT JOIN comment_agg ca    ON ca.forum_id = fb.forum_id
ORDER BY fb.forum_id
