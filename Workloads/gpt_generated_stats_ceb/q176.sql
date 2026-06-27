WITH
owner_posts AS (
    SELECT
        u.id AS id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
        COALESCE(AVG(p.viewcount), 0.0) AS avg_viewcount,
        COALESCE(SUM(p.answercount), 0) AS total_answercount,
        COALESCE(SUM(p.commentcount), 0) AS total_commentcount,
        COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
owner_comments_on_posts AS (
    SELECT
        u.id AS id,
        COUNT(c.id) AS comment_on_own_posts_count,
        COALESCE(SUM(c.score), 0) AS total_comment_on_own_posts_score
    FROM comments c
    JOIN posts p ON c.postid = p.id
    JOIN users u ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS id,
        COUNT(c.id) AS comment_made_count,
        COALESCE(SUM(c.score), 0) AS total_comment_made_score
    FROM comments c
    JOIN users u ON c.userid = u.id
    GROUP BY u.id
),
owner_tags AS (
    SELECT
        u.id AS id,
        COUNT(t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN users u ON p.owneruserid = u.id
    GROUP BY u.id
),
owner_postlinks_source AS (
    SELECT
        u.id AS id,
        COUNT(pl.id) AS postlink_source_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    JOIN users u ON p.owneruserid = u.id
    GROUP BY u.id
),
owner_postlinks_target AS (
    SELECT
        u.id AS id,
        COUNT(pl.id) AS postlink_target_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    JOIN users u ON p.owneruserid = u.id
    GROUP BY u.id
)

SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(op.post_count, 0) AS post_count,
    COALESCE(op.total_post_score, 0) AS total_post_score,
    COALESCE(op.total_viewcount, 0) AS total_viewcount,
    COALESCE(op.avg_viewcount, 0.0) AS avg_viewcount,
    COALESCE(op.total_answercount, 0) AS total_answercount,
    COALESCE(op.total_commentcount, 0) AS total_commentcount,
    COALESCE(op.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(oc.comment_on_own_posts_count, 0) AS comment_on_own_posts_count,
    COALESCE(oc.total_comment_on_own_posts_score, 0) AS total_comment_on_own_posts_score,
    COALESCE(uc.comment_made_count, 0) AS comment_made_count,
    COALESCE(uc.total_comment_made_score, 0) AS total_comment_made_score,
    COALESCE(ot.tag_count, 0) AS tag_count,
    COALESCE(ops.postlink_source_count, 0) AS postlink_source_count,
    COALESCE(opt.postlink_target_count, 0) AS postlink_target_count
FROM users u
LEFT JOIN owner_posts op ON op.id = u.id
LEFT JOIN owner_comments_on_posts oc ON oc.id = u.id
LEFT JOIN user_comments uc ON uc.id = u.id
LEFT JOIN owner_tags ot ON ot.id = u.id
LEFT JOIN owner_postlinks_source ops ON ops.id = u.id
LEFT JOIN owner_postlinks_target opt ON opt.id = u.id
ORDER BY u.reputation DESC
LIMIT 100
