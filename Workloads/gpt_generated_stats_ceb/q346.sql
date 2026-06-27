WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(p.id) AS total_posts,
           COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS answer_posts,
           COUNT(CASE WHEN p.posttypeid = 1 THEN 1 END) AS question_posts
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments_made AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comments_made
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_comments_received AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comments_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badges_earned
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_activity AS (
    SELECT u.id AS user_id,
           u.reputation,
           COALESCE(up.total_posts,0) AS total_posts,
           COALESCE(up.answer_posts,0) AS answer_posts,
           COALESCE(up.question_posts,0) AS question_posts,
           COALESCE(ucm.comments_made,0) AS comments_made,
           COALESCE(ucr.comments_received,0) AS comments_received,
           COALESCE(uvr.votes_received,0) AS votes_received,
           COALESCE(uvr.upvotes_received,0) AS upvotes_received,
           COALESCE(uvr.downvotes_received,0) AS downvotes_received,
           COALESCE(ub.badges_earned,0) AS badges_earned,
           (COALESCE(up.total_posts,0) * 2
            + COALESCE(ucm.comments_made,0) * 1
            + COALESCE(uvr.upvotes_received,0) * 3
            - COALESCE(uvr.downvotes_received,0) * 2
            + COALESCE(ub.badges_earned,0) * 5) AS activity_score
    FROM users u
    LEFT JOIN user_posts up ON up.user_id = u.id
    LEFT JOIN user_comments_made ucm ON ucm.user_id = u.id
    LEFT JOIN user_comments_received ucr ON ucr.user_id = u.id
    LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
    LEFT JOIN user_badges ub ON ub.user_id = u.id
)
SELECT ranked.user_id,
       ranked.reputation,
       ranked.total_posts,
       ranked.answer_posts,
       ranked.question_posts,
       ranked.comments_made,
       ranked.comments_received,
       ranked.votes_received,
       ranked.upvotes_received,
       ranked.downvotes_received,
       ranked.badges_earned,
       ranked.activity_score,
       ranked.activity_rank
FROM (
    SELECT ua.user_id,
           ua.reputation,
           ua.total_posts,
           ua.answer_posts,
           ua.question_posts,
           ua.comments_made,
           ua.comments_received,
           ua.votes_received,
           ua.upvotes_received,
           ua.downvotes_received,
           ua.badges_earned,
           ua.activity_score,
           ROW_NUMBER() OVER (ORDER BY ua.activity_score DESC) AS activity_rank
    FROM user_activity ua
) ranked
WHERE ranked.activity_rank <= 10
ORDER BY ranked.activity_rank
