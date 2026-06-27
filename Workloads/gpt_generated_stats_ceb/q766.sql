WITH
user_base AS (
    SELECT id, reputation
    FROM users
),
owned_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS owned_posts,
        SUM(score) AS owned_posts_score_sum,
        AVG(score) AS owned_posts_score_avg,
        SUM(viewcount) AS owned_posts_viewcount_sum
    FROM posts
    GROUP BY owneruserid
),
comments_made AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comments_made,
        SUM(score) AS comments_score_sum
    FROM comments
    GROUP BY userid
),
votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
badges_earned AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badges_earned
    FROM badges
    GROUP BY userid
),
posthistory_events AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS posthistory_events
    FROM posthistory
    GROUP BY userid
),
postlinks_owned AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlinks_owned
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
tags_on_owned_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tags_on_owned_posts
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ub.id AS user_id,
    ub.reputation,
    COALESCE(op.owned_posts, 0) AS owned_posts,
    COALESCE(op.owned_posts_score_sum, 0) AS owned_posts_score_sum,
    COALESCE(op.owned_posts_score_avg, 0) AS owned_posts_score_avg,
    COALESCE(op.owned_posts_viewcount_sum, 0) AS owned_posts_viewcount_sum,
    COALESCE(cm.comments_made, 0) AS comments_made,
    COALESCE(cm.comments_score_sum, 0) AS comments_score_sum,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(be.badges_earned, 0) AS badges_earned,
    COALESCE(ph.posthistory_events, 0) AS posthistory_events,
    COALESCE(pl.postlinks_owned, 0) AS postlinks_owned,
    COALESCE(tg.distinct_tags_on_owned_posts, 0) AS distinct_tags_on_owned_posts
FROM user_base ub
LEFT JOIN owned_posts op ON op.user_id = ub.id
LEFT JOIN comments_made cm ON cm.user_id = ub.id
LEFT JOIN votes_cast vc ON vc.user_id = ub.id
LEFT JOIN votes_received vr ON vr.user_id = ub.id
LEFT JOIN badges_earned be ON be.user_id = ub.id
LEFT JOIN posthistory_events ph ON ph.user_id = ub.id
LEFT JOIN postlinks_owned pl ON pl.user_id = ub.id
LEFT JOIN tags_on_owned_posts tg ON tg.user_id = ub.id
ORDER BY owned_posts DESC
LIMIT 100
