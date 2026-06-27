WITH
    user_reps AS (
        SELECT
            id,
            reputation
        FROM users
    ),
    post_metrics AS (
        SELECT
            p.owneruserid AS id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.viewcount) AS total_view_count
        FROM posts p
        GROUP BY p.owneruserid
    ),
    comment_metrics AS (
        SELECT
            c.userid AS id,
            COUNT(*) AS comment_count,
            SUM(c.score) AS total_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    vote_metrics AS (
        SELECT
            v.userid AS id,
            COUNT(*) AS vote_count,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_amount
        FROM votes v
        GROUP BY v.userid
    ),
    badge_metrics AS (
        SELECT
            b.userid AS id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    posthistory_metrics AS (
        SELECT
            ph.userid AS id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    tag_metrics AS (
        SELECT
            p.owneruserid AS id,
            COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_view_count, 0) AS total_view_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count
FROM user_reps u
LEFT JOIN post_metrics p ON p.id = u.id
LEFT JOIN comment_metrics c ON c.id = u.id
LEFT JOIN vote_metrics v ON v.id = u.id
LEFT JOIN badge_metrics b ON b.id = u.id
LEFT JOIN posthistory_metrics ph ON ph.id = u.id
LEFT JOIN tag_metrics t ON t.id = u.id
ORDER BY u.reputation DESC
LIMIT 100
