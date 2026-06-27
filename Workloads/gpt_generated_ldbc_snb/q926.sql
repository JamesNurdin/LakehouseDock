/*
   Analytical query for the LDBC SNB BI dataset (sf0003).
   For each forum it returns:
   • Basic forum info (id, title)
   • Number of posts and average post length
   • Number of comments and average comment length
   • Total likes on posts and on comments
   • Count of distinct participants (authors of posts or comments)
   • The most frequently used tag on posts in the forum and its usage count
   All joins follow the allowed join rules and only the selected tables/columns are used.
*/
WITH
-- Aggregate posts per forum
forum_posts_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),

-- Aggregate comments per forum (via the post they belong to)
forum_comments_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),

-- Total likes on posts per forum
post_likes_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS total_post_likes
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),

-- Total likes on comments per forum
comment_likes_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS total_comment_likes
    FROM person_likes_comment cl
    JOIN comment c ON cl.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),

-- Distinct participants (authors of posts or comments) per forum
forum_participants_agg AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS distinct_participant_count
    FROM (
        SELECT
            p.container_forum_id AS forum_id,
            p.creator_person_id AS person_id
        FROM post p
        UNION ALL
        SELECT
            p.container_forum_id AS forum_id,
            c.creator_person_id AS person_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
    ) t
    GROUP BY forum_id
),

-- Tag usage per forum (post tags only)
forum_tag_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        pht.tag_id,
        COUNT(*) AS tag_usage_count
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    GROUP BY p.container_forum_id, pht.tag_id
),

-- Most frequent tag per forum
forum_top_tag AS (
    SELECT
        forum_id,
        tag_id AS top_tag_id,
        tag_usage_count AS top_tag_usage_count
    FROM (
        SELECT
            forum_id,
            tag_id,
            tag_usage_count,
            ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage_count DESC) AS rn
        FROM forum_tag_counts
    ) ranked
    WHERE rn = 1
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pl.total_post_likes, 0) AS total_post_likes,
    COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(pa.distinct_participant_count, 0) AS distinct_participant_count,
    ft.top_tag_id,
    ft.top_tag_usage_count
FROM forum f
LEFT JOIN forum_posts_agg fp ON fp.forum_id = f.id
LEFT JOIN forum_comments_agg fc ON fc.forum_id = f.id
LEFT JOIN post_likes_agg pl ON pl.forum_id = f.id
LEFT JOIN comment_likes_agg cl ON cl.forum_id = f.id
LEFT JOIN forum_participants_agg pa ON pa.forum_id = f.id
LEFT JOIN forum_top_tag ft ON ft.forum_id = f.id
ORDER BY f.id
