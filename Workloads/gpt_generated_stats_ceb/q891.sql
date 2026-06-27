WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS post_score_sum,
        COALESCE(SUM(p.viewcount), 0) AS post_viewcount_sum,
        COALESCE(AVG(p.answercount), 0) AS avg_answer_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS vote_cast_count
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS post_edit_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(up.avg_answer_count, 0) AS avg_answer_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.post_edit_count, 0) AS post_edit_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
ORDER BY post_count DESC, comment_count DESC
LIMIT 50
