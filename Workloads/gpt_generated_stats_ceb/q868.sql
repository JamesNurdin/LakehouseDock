WITH badge_counts AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
post_stats AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS post_count,
        AVG(p.score) AS avg_post_score,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_views
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
vote_cast_stats AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
vote_received_stats AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.total_views, 0) AS total_views,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(cs.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN post_stats ps ON ps.owneruserid = u.id
LEFT JOIN comment_stats cs ON cs.userid = u.id
LEFT JOIN vote_cast_stats vc ON vc.userid = u.id
LEFT JOIN vote_received_stats vr ON vr.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 20
