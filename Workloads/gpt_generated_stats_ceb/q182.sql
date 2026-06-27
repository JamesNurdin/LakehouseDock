WITH user_post_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_posts,
        SUM(p.score) AS sum_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_post_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments_on_posts
    FROM posts p
    GROUP BY p.owneruserid
),
user_comment_metrics AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS total_comments_made,
        SUM(c.score) AS sum_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast_metrics AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS total_votes_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_votes_received,
        SUM(v.bountyamount) AS sum_bounty_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badge_metrics AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS total_badges
    FROM badges b
    GROUP BY b.userid
),
user_tag_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS total_tags_used
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)

SELECT
    u.id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.sum_post_score, 0) AS sum_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(uc.total_comments_made, 0) AS total_comments_made,
    COALESCE(uc.sum_comment_score, 0) AS sum_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(vr.sum_bounty_received, 0) AS sum_bounty_received,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(ut.total_tags_used, 0) AS total_tags_used
FROM users u
LEFT JOIN user_post_metrics up ON up.user_id = u.id
LEFT JOIN user_comment_metrics uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast_metrics vc ON vc.user_id = u.id
LEFT JOIN user_votes_received_metrics vr ON vr.user_id = u.id
LEFT JOIN user_badge_metrics ub ON ub.user_id = u.id
LEFT JOIN user_tag_metrics ut ON ut.user_id = u.id
ORDER BY total_posts DESC, u.reputation DESC
LIMIT 100
