WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        AVG(p.score) AS avg_post_score,
        MAX(p.creationdate) AS last_post_date
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        MAX(c.creationdate) AS last_comment_date
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
        MAX(v.creationdate) AS last_vote_date
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count,
        MAX(b."date") AS last_badge_date
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS post_history_entries,
        MAX(ph.creationdate) AS last_posthistory_date
    FROM posthistory ph
    GROUP BY ph.userid
)

SELECT
    u.id AS userid,
    u.reputation,
    u.creationdate AS user_creationdate,
    up.post_count,
    up.avg_post_score,
    up.last_post_date,
    uc.comment_count,
    uc.last_comment_date,
    uv.vote_count,
    uv.upvote_cast,
    uv.downvote_cast,
    uv.last_vote_date,
    ub.badge_count,
    ub.last_badge_date,
    uph.post_history_entries,
    uph.last_posthistory_date,
    (COALESCE(up.post_count,0) 
     + COALESCE(uc.comment_count,0) 
     + COALESCE(uv.vote_count,0) 
     + COALESCE(ub.badge_count,0) 
     + COALESCE(uph.post_history_entries,0)) AS total_activity
FROM users u
LEFT JOIN user_posts up          ON u.id = up.userid
LEFT JOIN user_comments uc       ON u.id = uc.userid
LEFT JOIN user_votes uv          ON u.id = uv.userid
LEFT JOIN user_badges ub         ON u.id = ub.userid
LEFT JOIN user_posthistory uph   ON u.id = uph.userid
ORDER BY total_activity DESC
LIMIT 100
