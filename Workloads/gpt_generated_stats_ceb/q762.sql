WITH
    user_posts AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS post_count,
               COALESCE(SUM(p.score), 0) AS total_post_score,
               COALESCE(SUM(p.answercount), 0) AS total_answer_count,
               COALESCE(SUM(p.commentcount), 0) AS total_post_comments,
               COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT c.userid AS user_id,
               COUNT(*) AS comment_count,
               COALESCE(SUM(c.score), 0) AS total_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT v.userid AS user_id,
               COUNT(*) AS votes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS votes_received
        FROM posts p
        JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT b.userid AS user_id,
               COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_tags AS (
        SELECT p.owneruserid AS user_id,
               COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_answer_count, 0) AS total_answer_count,
       COALESCE(up.total_post_comments, 0) AS total_post_comments,
       COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
       DENSE_RANK() OVER (ORDER BY COALESCE(up.total_post_score, 0) DESC) AS post_score_rank
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 20
