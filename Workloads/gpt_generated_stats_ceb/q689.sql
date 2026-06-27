WITH
user_base AS (
    SELECT id AS user_id,
           reputation,
           creationdate
    FROM users
),
user_posts AS (
    SELECT owneruserid AS user_id,
           count(*) AS post_count,
           sum(score) AS post_score_sum,
           sum(viewcount) AS post_view_sum,
           avg(viewcount) AS post_view_avg,
           max(score) AS post_max_score
    FROM posts
    GROUP BY owneruserid
),
user_last_edits AS (
    SELECT lasteditoruserid AS user_id,
           count(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT userid AS user_id,
           count(*) AS comment_count,
           sum(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid AS user_id,
           count(*) AS votes_cast_count,
           sum(bountyamount) AS bounty_amount_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           count(*) AS votes_received_count,
           sum(v.bountyamount) AS bounty_amount_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT userid AS user_id,
           count(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid AS user_id,
           count(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_posthistory_type AS (
    SELECT ph.userid AS user_id,
           count(*) AS posthistory_type_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
)

SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    coalesce(up.post_count, 0) AS post_count,
    coalesce(up.post_score_sum, 0) AS post_score_sum,
    coalesce(up.post_view_sum, 0) AS post_view_sum,
    coalesce(up.post_view_avg, 0.0) AS post_view_avg,
    coalesce(up.post_max_score, 0) AS post_max_score,
    coalesce(ule.edit_count, 0) AS edit_count,
    coalesce(uc.comment_count, 0) AS comment_count,
    coalesce(uc.comment_score_sum, 0) AS comment_score_sum,
    coalesce(uvc.votes_cast_count, 0) AS votes_cast_count,
    coalesce(uvc.bounty_amount_cast, 0) AS bounty_amount_cast,
    coalesce(uvr.votes_received_count, 0) AS votes_received_count,
    coalesce(uvr.bounty_amount_received, 0) AS bounty_amount_received,
    coalesce(ubg.badge_count, 0) AS badge_count,
    coalesce(uph.posthistory_count, 0) AS posthistory_count,
    coalesce(upht.posthistory_type_count, 0) AS posthistory_type_count,
    CASE
        WHEN coalesce(up.post_count, 0) > 0 THEN up.post_score_sum * 1.0 / up.post_count
        ELSE 0
    END AS avg_post_score,
    (coalesce(up.post_count, 0) +
     coalesce(uc.comment_count, 0) +
     coalesce(uvc.votes_cast_count, 0) +
     coalesce(uvr.votes_received_count, 0) +
     coalesce(ubg.badge_count, 0)) AS total_engagement,
    rank() OVER (ORDER BY coalesce(up.post_score_sum, 0) DESC) AS post_score_rank
FROM user_base ub
LEFT JOIN user_posts up ON ub.user_id = up.user_id
LEFT JOIN user_last_edits ule ON ub.user_id = ule.user_id
LEFT JOIN user_comments uc ON ub.user_id = uc.user_id
LEFT JOIN user_votes_cast uvc ON ub.user_id = uvc.user_id
LEFT JOIN user_votes_received uvr ON ub.user_id = uvr.user_id
LEFT JOIN user_badges ubg ON ub.user_id = ubg.user_id
LEFT JOIN user_posthistory uph ON ub.user_id = uph.user_id
LEFT JOIN user_posthistory_type upht ON ub.user_id = upht.user_id
WHERE ub.reputation > 1000
ORDER BY up.post_score_sum DESC
LIMIT 100
