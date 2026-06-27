WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_viewcount,
        SUM(answercount) AS total_answercount,
        SUM(commentcount) AS total_commentcount,
        SUM(favoritecount) AS total_favoritecount
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_given,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_given,
        SUM(bountyamount) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_given, 0) AS upvote_given,
    COALESCE(v.downvote_given, 0) AS downvote_given,
    COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(b.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN user_posts p ON u.id = p.user_id
LEFT JOIN user_edits e ON u.id = e.user_id
LEFT JOIN user_comments c ON u.id = c.user_id
LEFT JOIN user_votes v ON u.id = v.user_id
LEFT JOIN user_badges b ON u.id = b.user_id
ORDER BY u.reputation DESC
LIMIT 100
