WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS owned_posts,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_views
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS edited_posts
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast,
        SUM(COALESCE(bountyamount, 0)) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.owned_posts, 0) AS owned_posts,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(ue.edited_posts, 0) AS edited_posts,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(tg.tag_count, 0) AS tag_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory ph ON ph.user_id = u.id
LEFT JOIN user_tags tg ON tg.user_id = u.id
LEFT JOIN user_postlinks pl ON pl.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
