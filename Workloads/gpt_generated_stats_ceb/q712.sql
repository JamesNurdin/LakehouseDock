WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS post_score_sum,
            AVG(score) AS post_score_avg
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count
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
    user_edits AS (
        SELECT
            lasteditoruserid AS userid,
            COUNT(*) AS edit_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    )
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    p.post_score_avg,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts p
    ON u.id = p.userid
LEFT JOIN user_comments c
    ON u.id = c.userid
LEFT JOIN user_votes v
    ON u.id = v.userid
LEFT JOIN user_badges b
    ON u.id = b.userid
LEFT JOIN user_edits e
    ON u.id = e.userid
LEFT JOIN user_postlinks pl
    ON u.id = pl.userid
LEFT JOIN user_posthistory ph
    ON u.id = ph.userid
ORDER BY u.reputation DESC
LIMIT 100
