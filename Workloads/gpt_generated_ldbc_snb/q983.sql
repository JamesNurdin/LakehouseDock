WITH likes_per_post AS (
    SELECT post_id,
           COUNT(*) AS like_cnt
    FROM person_likes_post
    GROUP BY post_id
),
comments_per_post AS (
    SELECT parent_post_id AS post_id,
           COUNT(*) AS comment_cnt,
           AVG(length) AS avg_comment_length
    FROM comment
    GROUP BY parent_post_id
),
post_stats AS (
    SELECT p.id AS post_id,
           p.length AS post_length,
           p.creator_person_id,
           COALESCE(l.like_cnt, 0) AS like_cnt,
           COALESCE(c.comment_cnt, 0) AS comment_cnt,
           COALESCE(c.avg_comment_length, 0) AS avg_comment_length
    FROM post p
    LEFT JOIN likes_per_post l ON l.post_id = p.id
    LEFT JOIN comments_per_post c ON c.post_id = p.id
)
SELECT tht.tag_id,
       COUNT(DISTINCT ps.post_id) AS post_count,
       SUM(ps.like_cnt) AS total_likes,
       SUM(ps.comment_cnt) AS total_comments,
       AVG(ps.post_length) AS avg_post_length,
       AVG(ps.avg_comment_length) AS avg_comment_length,
       COUNT(DISTINCT ps.creator_person_id) AS distinct_creators
FROM post_has_tag_tag tht
JOIN post_stats ps ON ps.post_id = tht.post_id
GROUP BY tht.tag_id
ORDER BY total_likes DESC
LIMIT 10
