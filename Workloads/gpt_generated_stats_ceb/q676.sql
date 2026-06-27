WITH user_info AS (
    SELECT
        id AS user_id,
        reputation,
        creationdate,
        views,
        upvotes,
        downvotes
    FROM users
),
user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(SUM(viewcount), 0) AS total_post_views
    FROM posts
    GROUP BY owneruserid
),
user_votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast,
        COALESCE(SUM(bountyamount), 0) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_links AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_related_links AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS related_link_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ui.user_id,
    ui.reputation,
    ui.creationdate,
    ui.views,
    ui.upvotes,
    ui.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ul.link_count, 0) AS link_count,
    COALESCE(ur.related_link_count, 0) AS related_link_count
FROM user_info ui
LEFT JOIN user_posts up ON up.user_id = ui.user_id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = ui.user_id
LEFT JOIN user_votes_received uvr ON uvr.user_id = ui.user_id
LEFT JOIN user_comments uc ON uc.user_id = ui.user_id
LEFT JOIN user_badges ub ON ub.user_id = ui.user_id
LEFT JOIN user_edits ue ON ue.user_id = ui.user_id
LEFT JOIN user_links ul ON ul.user_id = ui.user_id
LEFT JOIN user_related_links ur ON ur.user_id = ui.user_id
ORDER BY ui.reputation DESC
LIMIT 20
