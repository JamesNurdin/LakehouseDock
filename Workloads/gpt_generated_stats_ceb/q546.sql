WITH user_badges AS (
    SELECT u.id AS user_id,
           u.reputation,
           u.creationdate,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id, u.reputation, u.creationdate
),
user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS owned_post_count,
           COALESCE(SUM(p.score), 0) AS owned_post_score_sum,
           AVG(p.score) AS owned_post_score_avg,
           COALESCE(SUM(p.viewcount), 0) AS owned_post_view_sum,
           COALESCE(SUM(p.answercount), 0) AS owned_post_answer_sum,
           COALESCE(SUM(p.commentcount), 0) AS owned_post_comment_sum,
           COALESCE(SUM(p.favoritecount), 0) AS owned_post_favorite_sum
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS comment_score_sum,
           AVG(c.score) AS comment_score_avg
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_count,
           COALESCE(SUM(v.bountyamount), 0) AS bounty_sum
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_post_interactions AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT p.id) AS owned_posts_interacted,
           COUNT(DISTINCT c.id) AS comments_on_owned_posts,
           COUNT(DISTINCT v.id) AS votes_on_owned_posts
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.postid = p.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS posthistory_count,
           COUNT(DISTINCT ph.postid) AS distinct_posts_in_history
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
)
SELECT ub.user_id,
       ub.reputation,
       ub.creationdate,
       ub.badge_count,
       up.owned_post_count,
       up.owned_post_score_sum,
       up.owned_post_score_avg,
       up.owned_post_view_sum,
       up.owned_post_answer_sum,
       up.owned_post_comment_sum,
       up.owned_post_favorite_sum,
       uc.comment_count,
       uc.comment_score_sum,
       uc.comment_score_avg,
       uv.vote_count,
       uv.bounty_sum,
       ui.owned_posts_interacted,
       ui.comments_on_owned_posts,
       ui.votes_on_owned_posts,
       uph.posthistory_count,
       uph.distinct_posts_in_history
FROM user_badges ub
LEFT JOIN user_posts up ON up.user_id = ub.user_id
LEFT JOIN user_comments uc ON uc.user_id = ub.user_id
LEFT JOIN user_votes uv ON uv.user_id = ub.user_id
LEFT JOIN user_post_interactions ui ON ui.user_id = ub.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 100
