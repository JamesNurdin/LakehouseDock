WITH
    user_posts AS (
        SELECT u.id,
               u.reputation,
               COUNT(p.id) AS post_count,
               COALESCE(SUM(p.score), 0) AS post_score_sum,
               COALESCE(SUM(p.answercount), 0) AS total_answer_count,
               COALESCE(SUM(p.commentcount), 0) AS total_comment_on_posts,
               COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
        FROM users u
        LEFT JOIN posts p
               ON p.owneruserid = u.id
        GROUP BY u.id, u.reputation
    ),
    user_comments AS (
        SELECT u.id,
               COUNT(c.id) AS comment_written_count
        FROM users u
        LEFT JOIN comments c
               ON c.userid = u.id
        GROUP BY u.id
    ),
    user_comments_on_posts AS (
        SELECT u.id,
               COUNT(c.id) AS comment_on_user_posts_count
        FROM users u
        LEFT JOIN posts p
               ON p.owneruserid = u.id
        LEFT JOIN comments c
               ON c.postid = p.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT u.id,
               COUNT(v.id) AS votes_cast_count
        FROM users u
        LEFT JOIN votes v
               ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT u.id,
               COUNT(v.id) AS votes_received_count
        FROM users u
        LEFT JOIN posts p
               ON p.owneruserid = u.id
        LEFT JOIN votes v
               ON v.postid = p.id
        GROUP BY u.id
    ),
    user_badges AS (
        SELECT u.id,
               COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b
               ON b.userid = u.id
        GROUP BY u.id
    ),
    user_posthistory AS (
        SELECT u.id,
               COUNT(ph.id) AS posthistory_count
        FROM users u
        LEFT JOIN posthistory ph
               ON ph.userid = u.id
        GROUP BY u.id
    ),
    user_postlinks_source AS (
        SELECT u.id,
               COUNT(pl.id) AS postlinks_source_count
        FROM users u
        LEFT JOIN posts p
               ON p.owneruserid = u.id
        LEFT JOIN postlinks pl
               ON pl.postid = p.id
        GROUP BY u.id
    ),
    user_postlinks_target AS (
        SELECT u.id,
               COUNT(pl.id) AS postlinks_target_count
        FROM users u
        LEFT JOIN posts p
               ON p.owneruserid = u.id
        LEFT JOIN postlinks pl
               ON pl.relatedpostid = p.id
        GROUP BY u.id
    )
SELECT
    up.id AS user_id,
    up.reputation,
    up.post_count,
    up.post_score_sum,
    up.total_answer_count,
    up.total_comment_on_posts,
    up.total_favorite_count,
    uc.comment_written_count,
    ucp.comment_on_user_posts_count,
    uv.votes_cast_count,
    uvr.votes_received_count,
    ub.badge_count,
    uph.posthistory_count,
    upls.postlinks_source_count,
    uplt.postlinks_target_count
FROM user_posts up
LEFT JOIN user_comments uc
       ON uc.id = up.id
LEFT JOIN user_comments_on_posts ucp
       ON ucp.id = up.id
LEFT JOIN user_votes_cast uv
       ON uv.id = up.id
LEFT JOIN user_votes_received uvr
       ON uvr.id = up.id
LEFT JOIN user_badges ub
       ON ub.id = up.id
LEFT JOIN user_posthistory uph
       ON uph.id = up.id
LEFT JOIN user_postlinks_source upls
       ON upls.id = up.id
LEFT JOIN user_postlinks_target uplt
       ON uplt.id = up.id
ORDER BY up.reputation DESC
LIMIT 100
