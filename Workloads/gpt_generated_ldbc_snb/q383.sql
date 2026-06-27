WITH person_post_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(post.id) AS post_count,
        AVG(post.length) AS avg_post_length,
        SUM(post.length) AS total_post_length
    FROM person p
    LEFT JOIN post ON post.creator_person_id = p.id
    GROUP BY p.id
),
person_comment_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        SUM(c.length) AS total_comment_length
    FROM person p
    LEFT JOIN comment c ON c.creator_person_id = p.id
    GROUP BY p.id
),
person_like_post_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(plp.post_id) AS likes_given_on_posts
    FROM person p
    LEFT JOIN person_likes_post plp ON plp.person_id = p.id
    GROUP BY p.id
),
person_like_comment_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(plc.comment_id) AS likes_given_on_comments
    FROM person p
    LEFT JOIN person_likes_comment plc ON plc.person_id = p.id
    GROUP BY p.id
),
person_tag_stats AS (
    SELECT
        pit.tag_id,
        COUNT(DISTINCT pit.person_id) AS person_count,
        COALESCE(SUM(ps.post_count), 0) AS total_posts,
        COALESCE(AVG(ps.avg_post_length), 0) AS avg_post_length,
        COALESCE(SUM(cs.comment_count), 0) AS total_comments,
        COALESCE(AVG(cs.avg_comment_length), 0) AS avg_comment_length,
        COALESCE(SUM(plps.likes_given_on_posts), 0) AS total_likes_given_on_posts,
        COALESCE(SUM(plcs.likes_given_on_comments), 0) AS total_likes_given_on_comments
    FROM person_has_interest_tag pit
    LEFT JOIN person p ON pit.person_id = p.id
    LEFT JOIN person_post_stats ps ON ps.person_id = p.id
    LEFT JOIN person_comment_stats cs ON cs.person_id = p.id
    LEFT JOIN person_like_post_stats plps ON plps.person_id = p.id
    LEFT JOIN person_like_comment_stats plcs ON plcs.person_id = p.id
    GROUP BY pit.tag_id
)
SELECT
    tag_id,
    person_count,
    total_posts,
    avg_post_length,
    total_comments,
    avg_comment_length,
    total_likes_given_on_posts,
    total_likes_given_on_comments
FROM person_tag_stats
ORDER BY total_posts DESC
LIMIT 10
