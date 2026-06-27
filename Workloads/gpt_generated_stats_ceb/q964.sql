WITH
user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
user_answers AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS answer_count
    FROM posts
    WHERE posttypeid = 2
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS userid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid AS userid,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        posts.owneruserid AS userid,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes
    JOIN posts ON votes.postid = posts.id
    GROUP BY posts.owneruserid
),
user_badges AS (
    SELECT
        userid AS userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid AS userid,
        COUNT(*) AS posthistory_events
    FROM posthistory
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
user_tags AS (
    SELECT
        posts.owneruserid AS userid,
        COUNT(DISTINCT tags.id) AS tag_count
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
    GROUP BY posts.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(a.answer_count, 0) AS answer_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_events, 0) AS posthistory_events,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    -- optional derived engagement metric
    (COALESCE(p.post_count,0) * 2
     + COALESCE(c.comment_count,0)
     + COALESCE(a.answer_count,0)
     + COALESCE(vr.upvotes_received,0)
     + COALESCE(vc.upvotes_cast,0)) AS engagement_score
FROM users u
LEFT JOIN user_posts p ON u.id = p.userid
LEFT JOIN user_answers a ON u.id = a.userid
LEFT JOIN user_comments c ON u.id = c.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_posthistory ph ON u.id = ph.userid
LEFT JOIN user_edits e ON u.id = e.userid
LEFT JOIN user_tags t ON u.id = t.userid
ORDER BY total_post_score DESC
LIMIT 100
