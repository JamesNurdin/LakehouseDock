WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(v.bountyamount) AS total_bounty
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_history AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS history_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_links AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.avg_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_post_views,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_count, 0) AS upvote_count,
    COALESCE(uv.downvote_count, 0) AS downvote_count,
    COALESCE(uv.total_bounty, 0) AS total_bounty,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(uh.history_count, 0) AS history_count,
    COALESCE(ul.link_count, 0) AS link_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
LEFT JOIN user_history uh ON uh.userid = u.id
LEFT JOIN user_links ul ON ul.userid = u.id
ORDER BY total_post_score DESC
LIMIT 20
