WITH
    user_posts AS (
        SELECT u.id AS userid,
               COUNT(p.id) AS post_count,
               COALESCE(SUM(p.score), 0) AS post_score_sum,
               COALESCE(SUM(p.viewcount), 0) AS post_view_sum
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT u.id AS userid,
               COUNT(c.id) AS comment_count,
               COALESCE(SUM(c.score), 0) AS comment_score_sum
        FROM users u
        LEFT JOIN comments c
            ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes AS (
        SELECT u.id AS userid,
               COUNT(v.id) AS vote_count,
               COALESCE(SUM(v.bountyamount), 0) AS bounty_sum
        FROM users u
        LEFT JOIN votes v
            ON v.userid = u.id
        GROUP BY u.id
    ),
    user_badges AS (
        SELECT u.id AS userid,
               COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b
            ON b.userid = u.id
        GROUP BY u.id
    ),
    user_edits AS (
        SELECT u.id AS userid,
               COUNT(ph.id) AS edit_count
        FROM users u
        LEFT JOIN posthistory ph
            ON ph.userid = u.id
        GROUP BY u.id
    ),
    user_tag_excerpts AS (
        SELECT u.id AS userid,
               COUNT(t.id) AS tag_excerpt_count
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        LEFT JOIN tags t
            ON t.excerptpostid = p.id
        GROUP BY u.id
    )
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.bounty_sum, 0) AS bounty_sum,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_tag_excerpts ut ON ut.userid = u.id
ORDER BY post_score_sum DESC
LIMIT 10
