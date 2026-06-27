WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           SUM(p.score) AS total_post_score,
           AVG(p.score) AS avg_post_score,
           COUNT(CASE WHEN p.posttypeid = 1 THEN 1 END) AS question_count,
           COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS answer_count,
           SUM(p.viewcount) AS total_views,
           SUM(p.favoritecount) AS total_favorites,
           SUM(p.commentcount) AS total_comments_on_posts
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_made_count,
           SUM(c.score) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_cast_count,
           COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_cast_count,
           COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_cast_count,
           SUM(v.bountyamount) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS posthistory_event_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       up.post_count,
       up.total_post_score,
       up.avg_post_score,
       up.question_count,
       up.answer_count,
       up.total_views,
       up.total_favorites,
       up.total_comments_on_posts,
       uc.comment_made_count,
       uc.total_comment_score,
       uv.vote_cast_count,
       uv.upvote_cast_count,
       uv.downvote_cast_count,
       uv.total_bounty_given,
       ub.badge_count,
       uh.posthistory_event_count,
       ut.distinct_tag_count
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_comments uc       ON uc.user_id = u.id
LEFT JOIN user_votes uv          ON uv.user_id = u.id
LEFT JOIN user_badges ub         ON ub.user_id = u.id
LEFT JOIN user_posthistory uh    ON uh.user_id = u.id
LEFT JOIN user_tags ut           ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 20
