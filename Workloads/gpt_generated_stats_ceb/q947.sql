WITH user_posts AS (
        SELECT u.id AS user_id,
               COUNT(p.id) AS post_count,
               COALESCE(SUM(p.score), 0) AS total_post_score,
               COALESCE(AVG(p.score), 0) AS avg_post_score,
               COALESCE(SUM(p.viewcount), 0) AS total_views,
               COALESCE(SUM(p.favoritecount), 0) AS total_favorites
        FROM users u
        LEFT JOIN posts p
               ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT u.id AS user_id,
               COUNT(c.id) AS comment_count,
               COALESCE(SUM(c.score), 0) AS total_comment_score
        FROM users u
        LEFT JOIN comments c
               ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes AS (
        SELECT u.id AS user_id,
               COUNT(v.id) AS vote_count,
               COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_cast,
               COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_cast
        FROM users u
        LEFT JOIN votes v
               ON v.userid = u.id
        GROUP BY u.id
    ),
    user_badges AS (
        SELECT u.id AS user_id,
               COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b
               ON b.userid = u.id
        GROUP BY u.id
    ),
    user_tags AS (
        SELECT u.id AS user_id,
               COUNT(DISTINCT t.id) AS tag_count
        FROM users u
        LEFT JOIN posts p
               ON p.owneruserid = u.id
        LEFT JOIN tags t
               ON t.excerptpostid = p.id
        GROUP BY u.id
    ),
    user_edits AS (
        SELECT u.id AS user_id,
               COUNT(ph.id) AS edit_count
        FROM users u
        LEFT JOIN posthistory ph
               ON ph.userid = u.id
        GROUP BY u.id
    )
SELECT u.id,
       u.reputation,
       up.post_count,
       up.total_post_score,
       up.avg_post_score,
       up.total_views,
       up.total_favorites,
       uc.comment_count,
       uc.total_comment_score,
       uv.vote_count,
       uv.upvote_cast,
       uv.downvote_cast,
       ub.badge_count,
       ut.tag_count,
       ue.edit_count
FROM users u
LEFT JOIN user_posts   up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes   uv ON uv.user_id = u.id
LEFT JOIN user_badges  ub ON ub.user_id = u.id
LEFT JOIN user_tags    ut ON ut.user_id = u.id
LEFT JOIN user_edits   ue ON ue.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
