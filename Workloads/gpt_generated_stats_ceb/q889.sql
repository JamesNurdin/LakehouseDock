WITH user_posts AS (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           SUM(score) AS post_score_total,
           AVG(score) AS post_score_avg,
           MIN(creationdate) AS first_post_date,
           MAX(creationdate) AS last_post_date
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_total,
           MIN(creationdate) AS first_comment_date,
           MAX(creationdate) AS last_comment_date
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid,
           COUNT(*) AS votes_cast,
           SUM(COALESCE(bountyamount, 0)) AS bounty_cast_total
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid,
           COUNT(*) AS votes_received,
           SUM(COALESCE(v.bountyamount, 0)) AS bounty_received_total
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count,
           MIN(date) AS first_badge_date,
           MAX(date) AS last_badge_date
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_posthistory_type AS (
    SELECT p.owneruserid,
           COUNT(*) AS posthistory_type_event_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT p.owneruserid,
           COUNT(DISTINCT t.id) AS distinct_tag_count,
           SUM(t.count) AS tag_use_sum
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT p.owneruserid,
           COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate AS account_created,
       COALESCE(up.post_count, 0)                      AS post_count,
       COALESCE(up.post_score_total, 0)                AS post_score_total,
       COALESCE(up.post_score_avg, 0)                  AS post_score_avg,
       up.first_post_date,
       up.last_post_date,
       COALESCE(uc.comment_count, 0)                   AS comment_count,
       COALESCE(uc.comment_score_total, 0)             AS comment_score_total,
       uc.first_comment_date,
       uc.last_comment_date,
       COALESCE(uvc.votes_cast, 0)                     AS votes_cast,
       COALESCE(uvc.bounty_cast_total, 0)              AS bounty_cast_total,
       COALESCE(uvr.votes_received, 0)                 AS votes_received,
       COALESCE(uvr.bounty_received_total, 0)          AS bounty_received_total,
       COALESCE(ub.badge_count, 0)                     AS badge_count,
       ub.first_badge_date,
       ub.last_badge_date,
       COALESCE(uph.posthistory_count, 0)              AS posthistory_count,
       COALESCE(upt.posthistory_type_event_count, 0)  AS posthistory_type_event_count,
       COALESCE(ut.distinct_tag_count, 0)              AS distinct_tag_count,
       COALESCE(ut.tag_use_sum, 0)                     AS tag_use_sum,
       COALESCE(ul.postlink_count, 0)                  AS postlink_count
FROM users u
LEFT JOIN user_posts up               ON up.owneruserid   = u.id
LEFT JOIN user_comments uc            ON uc.userid        = u.id
LEFT JOIN user_votes_cast uvc         ON uvc.userid       = u.id
LEFT JOIN user_votes_received uvr    ON uvr.owneruserid  = u.id
LEFT JOIN user_badges ub              ON ub.userid        = u.id
LEFT JOIN user_posthistory uph        ON uph.userid       = u.id
LEFT JOIN user_posthistory_type upt   ON upt.owneruserid  = u.id
LEFT JOIN user_tags ut                ON ut.owneruserid   = u.id
LEFT JOIN user_postlinks ul           ON ul.owneruserid   = u.id
ORDER BY u.reputation DESC
LIMIT 100
