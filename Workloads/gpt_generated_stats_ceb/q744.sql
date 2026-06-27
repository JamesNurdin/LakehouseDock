WITH user_posts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS post_count,
           AVG(p.score) AS avg_post_score,
           AVG(p.viewcount) AS avg_view_count,
           SUM(p.favoritecount) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT c.userid AS userid,
           COUNT(*) AS comment_count,
           AVG(c.score) AS avg_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT v.userid AS userid,
           COUNT(*) AS vote_count,
           SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_amount
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT b.userid AS userid,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_edits AS (
    SELECT p.lasteditoruserid AS userid,
           COUNT(*) AS edit_count
    FROM posts p
    GROUP BY p.lasteditoruserid
),
user_posthistory AS (
    SELECT ph.userid AS userid,
           COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(up.avg_view_count, 0) AS avg_view_count,
       COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(uv.total_bounty_amount, 0) AS total_bounty_amount,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       (COALESCE(up.post_count, 0) +
        COALESCE(uc.comment_count, 0) +
        COALESCE(uv.vote_count, 0) +
        COALESCE(ub.badge_count, 0) +
        COALESCE(ue.edit_count, 0) +
        COALESCE(uph.posthistory_count, 0)) AS total_activity
FROM users u
LEFT JOIN user_posts up       ON up.userid = u.id
LEFT JOIN user_comments uc    ON uc.userid = u.id
LEFT JOIN user_votes uv       ON uv.userid = u.id
LEFT JOIN user_badges ub      ON ub.userid = u.id
LEFT JOIN user_edits ue       ON ue.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
ORDER BY total_activity DESC
LIMIT 10
