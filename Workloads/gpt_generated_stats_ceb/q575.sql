WITH user_posts AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        MIN(creationdate) AS first_post_date,
        MAX(creationdate) AS last_post_date
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score,
        AVG(score) AS avg_comment_score,
        MIN(creationdate) AS first_comment_date,
        MAX(creationdate) AS last_comment_date
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast_count,
        SUM(COALESCE(bountyamount, 0)) AS total_bounty_cast
    FROM votes
    GROUP BY userid
),
votes_received AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS votes_received_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_tags AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    p.first_post_date,
    p.last_post_date,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    c.first_comment_date,
    c.last_comment_date,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN user_posts p ON u.id = p.owneruserid
LEFT JOIN user_comments c ON u.id = c.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN votes_received vr ON u.id = vr.owneruserid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_posthistory ph ON u.id = ph.userid
LEFT JOIN user_tags t ON u.id = t.owneruserid
WHERE u.creationdate >= current_timestamp - INTERVAL '5' YEAR
ORDER BY u.reputation DESC
LIMIT 100
