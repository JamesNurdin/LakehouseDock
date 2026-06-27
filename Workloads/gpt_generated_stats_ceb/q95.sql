WITH user_badges AS (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posts_owned AS (
    SELECT owneruserid, COUNT(*) AS post_owned_count,
           SUM(score) AS post_owned_score_sum,
           AVG(viewcount) AS post_owned_view_avg
    FROM posts
    GROUP BY owneruserid
),
user_posts_edited AS (
    SELECT lasteditoruserid, COUNT(*) AS post_edited_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT userid, COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid, COUNT(*) AS votes_cast_count,
           SUM(bountyamount) AS votes_cast_bounty_sum
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS userid, COUNT(*) AS votes_received_count,
           SUM(v.bountyamount) AS votes_received_bounty_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT userid, COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    ROW_NUMBER() OVER (ORDER BY u.reputation DESC) AS reputation_rank,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(upo.post_owned_count, 0) AS post_owned_count,
    COALESCE(upo.post_owned_score_sum, 0) AS post_owned_score_sum,
    COALESCE(upo.post_owned_view_avg, 0) AS post_owned_view_avg,
    COALESCE(ue.post_edited_count, 0) AS post_edited_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.votes_cast_bounty_sum, 0) AS votes_cast_bounty_sum,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.votes_received_bounty_sum, 0) AS votes_received_bounty_sum,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(uvr.votes_received_count, 0) / NULLIF(COALESCE(upo.post_owned_count, 0), 0) AS votes_received_per_owned_post,
    COALESCE(uc.comment_score_sum, 0) / NULLIF(COALESCE(uc.comment_count, 0), 0) AS avg_comment_score
FROM users u
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posts_owned upo ON upo.owneruserid = u.id
LEFT JOIN user_posts_edited ue ON ue.lasteditoruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
