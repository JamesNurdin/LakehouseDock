WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_view_count,
        COALESCE(AVG(p.score), 0) AS avg_post_score
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score,
        COALESCE(AVG(c.score), 0) AS avg_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_links AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvote_received, 0) AS upvote_received,
    COALESCE(uvr.downvote_received, 0) AS downvote_received,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(ul.postlink_count, 0) AS postlink_count,
    u.upvotes AS total_upvotes_given,
    u.downvotes AS total_downvotes_given
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
LEFT JOIN user_tags ut ON u.id = ut.userid
LEFT JOIN user_links ul ON u.id = ul.userid
ORDER BY total_post_score DESC
LIMIT 20
