WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.viewcount), 0) AS avg_viewcount,
        COALESCE(SUM(p.answercount), 0) AS total_answer_count,
        COALESCE(SUM(p.commentcount), 0) AS total_post_comment_count,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_votes AS (
    SELECT
        v.userid,
        COUNT(*) AS vote_cast_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM votes v
    GROUP BY v.userid
),
user_comments AS (
    SELECT
        c.userid,
        COUNT(*) AS comment_made_count
    FROM comments c
    GROUP BY c.userid
),
user_posthistory AS (
    SELECT
        ph.userid,
        COUNT(*) AS posthistory_event_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_viewcount, 0) AS avg_viewcount,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_post_comment_count, 0) AS total_post_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uv.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(uv.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(uc.comment_made_count, 0) AS comment_made_count,
    COALESCE(uph.posthistory_event_count, 0) AS posthistory_event_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
ORDER BY total_post_score DESC
LIMIT 100
