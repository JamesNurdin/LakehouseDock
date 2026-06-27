WITH user_posts AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments,
        SUM(p.viewcount) AS total_post_views,
        SUM(p.favoritecount) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT
        p.lasteditoruserid,
        COUNT(*) AS edited_post_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_links_source AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS source_link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    WHERE pl.linktypeid = 1
    GROUP BY p.owneruserid
),
user_links_target AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS target_link_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    WHERE pl.linktypeid = 1
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid,
        COUNT(DISTINCT t.id) AS distinct_tag_count,
        SUM(t.count) AS total_tag_usage
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views AS profile_views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_score,
    COALESCE(up.avg_score, 0) AS avg_score,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments, 0) AS total_comments,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(ue.edited_post_count, 0) AS edited_post_count,
    COALESCE(uls.source_link_count, 0) AS source_link_count,
    COALESCE(ult.target_link_count, 0) AS target_link_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(ut.total_tag_usage, 0) AS total_tag_usage
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_edits ue ON ue.lasteditoruserid = u.id
LEFT JOIN user_links_source uls ON uls.owneruserid = u.id
LEFT JOIN user_links_target ult ON ult.owneruserid = u.id
LEFT JOIN user_tags ut ON ut.owneruserid = u.id
ORDER BY total_score DESC
LIMIT 100
