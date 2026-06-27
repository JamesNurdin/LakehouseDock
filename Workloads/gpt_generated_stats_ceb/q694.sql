WITH user_base AS (
    SELECT
        id AS user_id,
        reputation,
        creationdate,
        views,
        upvotes,
        downvotes
    FROM users
),
post_metrics AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS total_posts,
        COALESCE(SUM(score), 0) AS total_post_score,
        MAX(creationdate) AS last_post_creationdate
    FROM posts
    GROUP BY owneruserid
),
vote_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS total_votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
comment_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(c.id) AS total_comments_on_posts,
        COALESCE(SUM(c.score), 0) AS total_comment_score_on_posts
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
badge_metrics AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),
posthistory_metrics AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_post_edits
    FROM posthistory
    GROUP BY userid
),
postlink_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS total_postlinks
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(pm.total_posts, 0) AS total_posts,
    COALESCE(pm.total_post_score, 0) AS total_post_score,
    COALESCE(pm.last_post_creationdate, TIMESTAMP '1970-01-01 00:00:00 UTC') AS last_post_creationdate,
    COALESCE(vm.total_votes_received, 0) AS total_votes_received,
    COALESCE(cm.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(cm.total_comment_score_on_posts, 0) AS total_comment_score_on_posts,
    COALESCE(bm.total_badges, 0) AS total_badges,
    COALESCE(phm.total_post_edits, 0) AS total_post_edits,
    COALESCE(plm.total_postlinks, 0) AS total_postlinks
FROM user_base ub
LEFT JOIN post_metrics pm ON ub.user_id = pm.user_id
LEFT JOIN vote_metrics vm ON ub.user_id = vm.user_id
LEFT JOIN comment_metrics cm ON ub.user_id = cm.user_id
LEFT JOIN badge_metrics bm ON ub.user_id = bm.user_id
LEFT JOIN posthistory_metrics phm ON ub.user_id = phm.user_id
LEFT JOIN postlink_metrics plm ON ub.user_id = plm.user_id
ORDER BY total_posts DESC, ub.reputation DESC
LIMIT 10
