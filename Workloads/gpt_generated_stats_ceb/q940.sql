WITH
    user_base AS (
        SELECT u.id AS user_id,
               u.reputation
        FROM users u
    ),
    user_posts AS (
        SELECT u.id AS user_id,
               COUNT(p.id) AS post_count,
               COALESCE(SUM(p.score), 0) AS total_post_score,
               COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
               COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
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
               COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 WHEN v.votetypeid = 3 THEN -1 ELSE 0 END), 0) AS net_vote_score
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
    user_edits AS (
        SELECT u.id AS user_id,
               COUNT(ph.id) AS edit_count
        FROM users u
        LEFT JOIN posthistory ph
            ON ph.userid = u.id
        GROUP BY u.id
    ),
    user_tags AS (
        SELECT u.id AS user_id,
               COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        LEFT JOIN tags t
            ON t.excerptpostid = p.id
        GROUP BY u.id
    ),
    user_links AS (
        SELECT u.id AS user_id,
               COUNT(DISTINCT pl.id) AS distinct_link_count
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        LEFT JOIN postlinks pl
            ON pl.postid = p.id
        GROUP BY u.id
    )
SELECT ub.user_id,
       ub.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_viewcount, 0) AS total_viewcount,
       COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(uv.net_vote_score, 0) AS net_vote_score,
       COALESCE(ubg.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(ul.distinct_link_count, 0) AS distinct_link_count
FROM user_base ub
LEFT JOIN user_posts up
    ON up.user_id = ub.user_id
LEFT JOIN user_comments uc
    ON uc.user_id = ub.user_id
LEFT JOIN user_votes uv
    ON uv.user_id = ub.user_id
LEFT JOIN user_badges ubg
    ON ubg.user_id = ub.user_id
LEFT JOIN user_edits ue
    ON ue.user_id = ub.user_id
LEFT JOIN user_tags ut
    ON ut.user_id = ub.user_id
LEFT JOIN user_links ul
    ON ul.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 20
