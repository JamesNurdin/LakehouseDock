/*
  User‑centric analytical view – for each user we aggregate activity across the
  Stack Exchange data model: posts owned, comments made, votes cast and received,
  badges earned, post‑history entries, tag excerpts on owned posts and post links.
  The query follows the allowed join paths and uses only the listed tables/columns.
*/
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS post_score_sum,
        AVG(p.score) AS post_score_avg,
        SUM(p.viewcount) AS post_viewcount_sum,
        SUM(p.answercount) AS post_answercount_sum,
        SUM(p.commentcount) AS post_commentcount_sum,
        SUM(p.favoritecount) AS post_favoritecount_sum
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count,
        SUM(v.bountyamount) AS bounty_amount_cast_sum
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count,
        SUM(v.bountyamount) AS bounty_amount_received_sum
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        SUM(t.count) AS tag_count_sum
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS postlink_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0)               AS post_count,
    COALESCE(up.post_score_sum, 0)           AS post_score_sum,
    COALESCE(up.post_score_avg, 0)           AS post_score_avg,
    COALESCE(up.post_viewcount_sum, 0)      AS post_viewcount_sum,
    COALESCE(up.post_answercount_sum, 0)    AS post_answercount_sum,
    COALESCE(up.post_commentcount_sum, 0)   AS post_commentcount_sum,
    COALESCE(up.post_favoritecount_sum, 0)  AS post_favoritecount_sum,
    COALESCE(uc.comment_count, 0)            AS comment_count,
    COALESCE(uc.comment_score_sum, 0)       AS comment_score_sum,
    COALESCE(uc.comment_score_avg, 0)       AS comment_score_avg,
    COALESCE(vc.votes_cast_count, 0)        AS votes_cast_count,
    COALESCE(vc.upvote_cast_count, 0)       AS upvote_cast_count,
    COALESCE(vc.downvote_cast_count, 0)     AS downvote_cast_count,
    COALESCE(vc.bounty_amount_cast_sum, 0)  AS bounty_amount_cast_sum,
    COALESCE(vr.votes_received_count, 0)    AS votes_received_count,
    COALESCE(vr.upvote_received_count, 0)   AS upvote_received_count,
    COALESCE(vr.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(vr.bounty_amount_received_sum, 0) AS bounty_amount_received_sum,
    COALESCE(ub.badge_count, 0)             AS badge_count,
    COALESCE(uph.posthistory_count, 0)      AS posthistory_count,
    COALESCE(ut.tag_count_sum, 0)           AS tag_count_sum,
    COALESCE(up_links.postlink_count, 0)    AS postlink_count
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_comments uc       ON uc.user_id = u.id
LEFT JOIN user_votes_cast vc    ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges ub        ON ub.user_id = u.id
LEFT JOIN user_posthistory uph  ON uph.user_id = u.id
LEFT JOIN user_tags ut          ON ut.user_id = u.id
LEFT JOIN user_postlinks up_links ON up_links.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
