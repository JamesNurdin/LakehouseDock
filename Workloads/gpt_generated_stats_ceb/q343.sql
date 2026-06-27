WITH
    user_posts AS (
        SELECT u.id AS user_id,
               COUNT(p.id) AS post_count,
               COALESCE(AVG(p.score), 0) AS avg_post_score,
               COALESCE(SUM(p.viewcount), 0) AS total_post_views,
               COALESCE(SUM(p.favoritecount), 0) AS total_favorites
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT u.id AS user_id,
               COUNT(c.id) AS comment_count,
               COALESCE(AVG(c.score), 0) AS avg_comment_score
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes AS (
        SELECT u.id AS user_id,
               COUNT(v.id) AS vote_cast_count,
               COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast,
               COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    user_badges AS (
        SELECT u.id AS user_id,
               COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b ON b.userid = u.id
        GROUP BY u.id
    ),
    user_edits AS (
        SELECT u.id AS user_id,
               COUNT(p.id) AS edit_count
        FROM users u
        LEFT JOIN posts p ON p.lasteditoruserid = u.id
        GROUP BY u.id
    ),
    user_posthistory AS (
        SELECT u.id AS user_id,
               COUNT(ph.id) AS posthistory_count
        FROM users u
        LEFT JOIN posthistory ph ON ph.userid = u.id
        LEFT JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY u.id
    )
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views AS profile_views,
       u.upvotes,
       u.downvotes,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(up.total_post_views, 0) AS total_post_views,
       COALESCE(up.total_favorites, 0) AS total_favorites,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
       COALESCE(uv.upvote_cast, 0) AS upvote_cast,
       COALESCE(uv.downvote_cast, 0) AS downvote_cast,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_comments uc       ON uc.user_id = u.id
LEFT JOIN user_votes uv          ON uv.user_id = u.id
LEFT JOIN user_badges ub         ON ub.user_id = u.id
LEFT JOIN user_edits ue          ON ue.user_id = u.id
LEFT JOIN user_posthistory uph   ON uph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
