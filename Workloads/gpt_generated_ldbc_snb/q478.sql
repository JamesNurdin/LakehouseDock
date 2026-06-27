WITH likes_per_post AS (
    SELECT
        plp.post_id AS post_id,
        COUNT(DISTINCT plp.person_id) AS post_likes
    FROM person_likes_post plp
    GROUP BY plp.post_id
),
comments_per_post AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.parent_post_id
),
post_stats AS (
    SELECT
        po.id AS post_id,
        COALESCE(lpp.post_likes, 0) AS post_likes,
        COALESCE(cpp.comment_count, 0) AS comment_count,
        cpp.avg_comment_length
    FROM post po
    LEFT JOIN likes_per_post lpp ON lpp.post_id = po.id
    LEFT JOIN comments_per_post cpp ON cpp.post_id = po.id
)
SELECT
    org.id AS company_id,
    org.name AS company_name,
    COUNT(DISTINCT po.id) AS num_posts,
    SUM(ps.post_likes) AS total_post_likes,
    SUM(ps.comment_count) AS total_comments,
    AVG(ps.avg_comment_length) AS avg_comment_length_across_posts
FROM person_work_at_company pwc
JOIN organisation org ON pwc.company_id = org.id
JOIN person p ON pwc.person_id = p.id
JOIN post po ON po.creator_person_id = p.id
LEFT JOIN post_stats ps ON ps.post_id = po.id
GROUP BY org.id, org.name
ORDER BY total_post_likes DESC
LIMIT 100
