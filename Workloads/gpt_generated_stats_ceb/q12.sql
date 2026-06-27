WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(AVG(p.score), 0) AS avg_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_post_views,
           COALESCE(SUM(p.answercount), 0) AS total_answers_received,
           COALESCE(SUM(p.favoritecount), 0) AS total_favorites,
           COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score,
           COALESCE(AVG(c.score), 0) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS user_id,
           COALESCE(SUM(t.count), 0) AS total_tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(up.total_post_views, 0) AS total_post_views,
       COALESCE(up.total_answers_received, 0) AS total_answers_received,
       COALESCE(up.total_favorites, 0) AS total_favorites,
       COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
       COALESCE(ut.total_tag_count, 0) AS total_tag_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 10
