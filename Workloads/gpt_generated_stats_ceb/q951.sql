WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        AVG(answercount) AS avg_answer_count,
        SUM(commentcount) AS total_comment_count
    FROM posts
    GROUP BY owneruserid
),
user_votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast,
        COUNT(DISTINCT postid) AS distinct_posts_voted
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
user_comments_made AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_tags_on_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.avg_answer_count, 0) AS avg_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ucm.comment_count, 0) AS comment_count,
    COALESCE(ucm.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(utp.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_comments_made ucm ON u.id = ucm.userid
LEFT JOIN user_tags_on_posts utp ON u.id = utp.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
ORDER BY post_score_sum DESC
LIMIT 10
