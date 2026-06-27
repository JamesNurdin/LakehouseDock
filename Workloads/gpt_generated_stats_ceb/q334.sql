WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        SUM(viewcount) AS view_count_sum,
        SUM(answercount) AS answer_count_sum,
        SUM(commentcount) AS comment_count_sum,
        SUM(favoritecount) AS favorite_count_sum
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_made_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS vote_cast_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count,
        SUM(bountyamount) AS bounty_total
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
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
    COALESCE(p.view_count_sum, 0) AS view_count_sum,
    COALESCE(p.answer_count_sum, 0) AS answer_count_sum,
    COALESCE(p.comment_count_sum, 0) AS comment_count_sum,
    COALESCE(p.favorite_count_sum, 0) AS favorite_count_sum,
    COALESCE(c.comment_made_count, 0) AS comment_made_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(v.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(v.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(v.bounty_total, 0) AS bounty_total,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(h.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts p ON p.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_posthistory h ON h.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
