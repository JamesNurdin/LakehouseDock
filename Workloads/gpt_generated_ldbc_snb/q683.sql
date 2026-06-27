WITH forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT f.id AS forum_id,
           COUNT(plp.person_id) AS post_like_count
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY f.id
),
forum_post_tags AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT pht.tag_id) AS distinct_post_tag_count
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(plc.person_id) AS comment_like_count
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN comment c
        ON c.parent_post_id = p.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY f.id
),
forum_comment_tags AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT cht.tag_id) AS distinct_comment_tag_count
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN comment c
        ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    GROUP BY f.id
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       COALESCE(fm.member_count, 0) AS member_count,
       COALESCE(fp.post_count, 0) AS post_count,
       COALESCE(fp.avg_post_length, 0) AS avg_post_length,
       COALESCE(fpl.post_like_count, 0) AS post_like_count,
       COALESCE(fpt.distinct_post_tag_count, 0) AS distinct_post_tag_count,
       COALESCE(fc.comment_count, 0) AS comment_count,
       COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(fcl.comment_like_count, 0) AS comment_like_count,
       COALESCE(fct.distinct_comment_tag_count, 0) AS distinct_comment_tag_count,
       CASE
           WHEN COALESCE(fp.post_count, 0) = 0 THEN 0
           ELSE COALESCE(fpl.post_like_count, 0) * 1.0 / COALESCE(fp.post_count, 1)
       END AS avg_likes_per_post,
       CASE
           WHEN COALESCE(fp.post_count, 0) = 0 THEN 0
           ELSE COALESCE(fc.comment_count, 0) * 1.0 / COALESCE(fp.post_count, 1)
       END AS avg_comments_per_post,
       CASE
           WHEN COALESCE(fc.comment_count, 0) = 0 THEN 0
           ELSE COALESCE(fcl.comment_like_count, 0) * 1.0 / COALESCE(fc.comment_count, 1)
       END AS avg_likes_per_comment
FROM forum f
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_post_likes fpl ON fpl.forum_id = f.id
LEFT JOIN forum_post_tags fpt ON fpt.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = f.id
LEFT JOIN forum_comment_tags fct ON fct.forum_id = f.id
ORDER BY member_count DESC
LIMIT 20
