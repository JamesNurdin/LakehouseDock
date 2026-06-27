WITH likes_per_post AS (
    SELECT
        plp.post_id,
        COUNT(*) AS like_count
    FROM person_likes_post plp
    GROUP BY plp.post_id
),
comments_per_post AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(*) AS comment_count
    FROM comment c
    GROUP BY c.parent_post_id
),
forum_agg AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(like_counts.like_count), 0) AS total_likes,
        COALESCE(SUM(comment_counts.comment_count), 0) AS total_comments,
        SUM(CASE WHEN per.gender = 'male' THEN 1 ELSE 0 END) AS male_member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN person per
        ON per.id = fm.person_id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN likes_per_post like_counts
        ON like_counts.post_id = p.id
    LEFT JOIN comments_per_post comment_counts
        ON comment_counts.post_id = p.id
    GROUP BY f.id, f.title
)
SELECT
    forum_id,
    forum_title,
    member_count,
    post_count,
    total_likes,
    total_comments,
    CASE
        WHEN member_count = 0 THEN NULL
        ELSE 100.0 * male_member_count / member_count
    END AS male_member_percentage,
    CASE
        WHEN post_count = 0 THEN NULL
        ELSE total_likes * 1.0 / post_count
    END AS avg_likes_per_post,
    CASE
        WHEN post_count = 0 THEN NULL
        ELSE total_comments * 1.0 / post_count
    END AS avg_comments_per_post
FROM forum_agg
ORDER BY member_count DESC
LIMIT 20
