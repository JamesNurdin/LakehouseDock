WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        COUNT(DISTINCT p.posttypeid) AS distinct_posttype_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS postlink_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tag_excerpt_count,
        SUM(t.count) AS total_tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.distinct_posttype_count, 0) AS distinct_posttype_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vc.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(vr.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count,
    COALESCE(tg.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(tg.total_tag_count, 0) AS total_tag_count,
    CASE
        WHEN COALESCE(uc.total_comment_score, 0) = 0 THEN NULL
        ELSE CAST(COALESCE(up.total_post_score, 0) AS double) / COALESCE(uc.total_comment_score, 0)
    END AS post_to_comment_score_ratio
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_edits e ON e.user_id = u.id
LEFT JOIN user_postlinks pl ON pl.user_id = u.id
LEFT JOIN user_tags tg ON tg.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
