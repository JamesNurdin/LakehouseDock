WITH post_stats AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        AVG(score) AS post_score_avg,
        SUM(viewcount) AS post_view_sum,
        SUM(answercount) AS post_answer_sum,
        SUM(commentcount) AS post_comment_sum,
        SUM(favoritecount) AS post_favorite_sum
    FROM posts
    GROUP BY owneruserid
),
comment_stats AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum,
        AVG(score) AS comment_score_avg
    FROM comments
    GROUP BY userid
),
vote_cast_stats AS (
    SELECT
        userid,
        COUNT(*) AS vote_cast_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM votes
    GROUP BY userid
),
vote_received_stats AS (
    SELECT
        p.owneruserid,
        COUNT(v.id) AS vote_received_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
badge_stats AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
)
SELECT
    u.id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    COALESCE(p.post_score_avg, 0) AS post_score_avg,
    COALESCE(p.post_view_sum, 0) AS post_view_sum,
    COALESCE(p.post_answer_sum, 0) AS post_answer_sum,
    COALESCE(p.post_comment_sum, 0) AS post_comment_sum,
    COALESCE(p.post_favorite_sum, 0) AS post_favorite_sum,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(c.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vr.vote_received_count, 0) AS vote_received_count,
    COALESCE(b.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN post_stats p ON p.owneruserid = u.id
LEFT JOIN comment_stats c ON c.userid = u.id
LEFT JOIN vote_cast_stats vc ON vc.userid = u.id
LEFT JOIN vote_received_stats vr ON vr.owneruserid = u.id
LEFT JOIN badge_stats b ON b.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
