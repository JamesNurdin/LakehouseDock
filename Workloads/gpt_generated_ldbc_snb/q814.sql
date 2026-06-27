WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        COUNT(DISTINCT pl.person_id) AS like_count,
        COUNT(DISTINCT c.id) AS comment_count
    FROM post p
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY p.id
),
post_univ_tag AS (
    SELECT
        p.id AS post_id,
        u.id AS university_id,
        u.name AS university_name,
        it.tag_id AS tag_id,
        pm.like_count,
        pm.comment_count
    FROM post p
    JOIN person creator ON p.creator_person_id = creator.id
    JOIN person_study_at_university s ON creator.id = s.person_id
    JOIN organisation u ON s.university_id = u.id
    JOIN person_has_interest_tag it ON creator.id = it.person_id
    JOIN post_metrics pm ON pm.post_id = p.id
)
SELECT
    university_name,
    tag_id,
    COUNT(post_id) AS num_posts,
    SUM(like_count) AS total_likes,
    AVG(like_count) AS avg_likes_per_post,
    SUM(comment_count) AS total_comments,
    AVG(comment_count) AS avg_comments_per_post
FROM post_univ_tag
GROUP BY university_name, tag_id
ORDER BY total_likes DESC
LIMIT 20
