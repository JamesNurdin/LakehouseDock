WITH
user_posts_agg AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        SUM(viewcount) AS total_views,
        SUM(answercount) AS total_answers,
        SUM(commentcount) AS total_comments_on_posts
    FROM posts
    GROUP BY owneruserid
),
user_edits_agg AS (
    SELECT
        lasteditoruserid AS userid,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments_agg AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast_agg AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received_agg AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges_agg AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory_agg AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) + COALESCE(vc.votes_cast, 0) + COALESCE(vr.votes_received, 0) + COALESCE(b.badge_count, 0) + COALESCE(ph.posthistory_count, 0)) AS total_activity
FROM users u
LEFT JOIN user_posts_agg p ON p.userid = u.id
LEFT JOIN user_edits_agg e ON e.userid = u.id
LEFT JOIN user_comments_agg c ON c.userid = u.id
LEFT JOIN user_votes_cast_agg vc ON vc.userid = u.id
LEFT JOIN user_votes_received_agg vr ON vr.userid = u.id
LEFT JOIN user_badges_agg b ON b.userid = u.id
LEFT JOIN user_posthistory_agg ph ON ph.userid = u.id
ORDER BY total_activity DESC
LIMIT 10
