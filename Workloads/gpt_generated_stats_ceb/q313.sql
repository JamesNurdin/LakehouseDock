WITH post_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
        COALESCE(SUM(p.answercount), 0) AS total_answercount,
        COALESCE(SUM(p.commentcount), 0) AS total_post_commentcount,
        COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
comment_agg AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_written_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
vote_agg AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_cast_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_cast_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_cast_count
    FROM votes v
    GROUP BY v.userid
),
badge_agg AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
posthistory_agg AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_answercount, 0) AS total_answercount,
    COALESCE(p.total_post_commentcount, 0) AS total_post_commentcount,
    COALESCE(p.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(c.comment_written_count, 0) AS comment_written_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(v.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(v.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN post_agg p ON p.user_id = u.id
LEFT JOIN comment_agg c ON c.user_id = u.id
LEFT JOIN vote_agg v ON v.user_id = u.id
LEFT JOIN badge_agg b ON b.user_id = u.id
LEFT JOIN posthistory_agg ph ON ph.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 50
