WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS post_score_sum,
           COALESCE(SUM(p.viewcount), 0) AS post_view_sum,
           COALESCE(SUM(p.answercount), 0) AS post_answer_sum
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS comment_score_sum
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
           COUNT(v.id) AS votes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
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
           COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_ph_type_posts AS (
    SELECT u.id AS user_id,
           COUNT(p2.id) AS ph_type_post_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN posts p2 ON ph.posthistorytypeid = p2.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.post_score_sum, 0) AS post_score_sum,
       COALESCE(ue.edited_post_count, 0) AS edited_post_count,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       COALESCE(upht.ph_type_post_count, 0) AS ph_type_post_count
FROM users u
LEFT JOIN user_posts up      ON up.user_id = u.id
LEFT JOIN user_edits ue      ON ue.user_id = u.id
LEFT JOIN user_comments uc   ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub     ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_ph_type_posts upht ON upht.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
