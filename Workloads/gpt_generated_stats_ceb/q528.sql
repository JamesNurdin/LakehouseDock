WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS post_score_sum,
            SUM(viewcount) AS post_view_sum
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid,
            COUNT(*) AS vote_count
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM posts p
        JOIN tags t
            ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM posts p
        JOIN postlinks pl
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS posthistory_count
        FROM posts p
        JOIN posthistory ph
            ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    CASE WHEN COALESCE(up.post_count, 0) > 0
        THEN CAST(COALESCE(up.post_score_sum, 0) AS double) / up.post_count
        ELSE NULL
    END AS avg_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    CASE WHEN COALESCE(uc.comment_count, 0) > 0
        THEN CAST(COALESCE(uc.comment_score_sum, 0) AS double) / uc.comment_count
        ELSE NULL
    END AS avg_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(ulp.postlink_count, 0) AS postlink_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up       ON up.userid = u.id
LEFT JOIN user_comments uc    ON uc.userid = u.id
LEFT JOIN user_votes uv       ON uv.userid = u.id
LEFT JOIN user_badges ub      ON ub.userid = u.id
LEFT JOIN user_tags ut        ON ut.userid = u.id
LEFT JOIN user_postlinks ulp  ON ulp.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
ORDER BY post_score_sum DESC
LIMIT 100
