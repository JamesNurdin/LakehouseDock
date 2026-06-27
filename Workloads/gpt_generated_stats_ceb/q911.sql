WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        AVG(score) AS avg_post_score,
        AVG(viewcount) AS avg_viewcount,
        SUM(answercount) AS total_answers,
        SUM(commentcount) AS total_comments_on_posts
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast,
        COUNT(DISTINCT postid) AS distinct_posts_voted
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.avg_viewcount, 0) AS avg_viewcount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_comments uc       ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc    ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub         ON ub.user_id = u.id
LEFT JOIN user_posthistory uph   ON uph.user_id = u.id
LEFT JOIN user_tags ut           ON ut.user_id = u.id
WHERE u.reputation > 1000
ORDER BY post_count DESC, u.id
LIMIT 100
