WITH
user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS post_score_sum,
        SUM(p.viewcount) AS post_viewcount_sum,
        SUM(p.answercount) AS post_answercount_sum,
        SUM(p.commentcount) AS post_commentcount_sum,
        SUM(p.favoritecount) AS post_favoritecount_sum
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS comment_score_sum
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS bounty_given_sum
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS bounty_received_sum
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
        COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    CASE WHEN COALESCE(up.post_count, 0) = 0 THEN 0
         ELSE COALESCE(up.post_score_sum, 0) * 1.0 / COALESCE(up.post_count, 0) END AS post_score_avg,
    COALESCE(up.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(up.post_answercount_sum, 0) AS post_answercount_sum,
    COALESCE(up.post_commentcount_sum, 0) AS post_commentcount_sum,
    COALESCE(up.post_favoritecount_sum, 0) AS post_favoritecount_sum,
    COALESCE(ue.edited_post_count, 0) AS edited_post_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.bounty_given_sum, 0) AS bounty_given_sum,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.bounty_received_sum, 0) AS bounty_received_sum,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_edits ue
    ON ue.user_id = u.id
LEFT JOIN user_comments uc
    ON uc.user_id = u.id
LEFT JOIN user_votes_cast vc
    ON vc.user_id = u.id
LEFT JOIN user_votes_received vr
    ON vr.user_id = u.id
LEFT JOIN user_badges ub
    ON ub.user_id = u.id
LEFT JOIN user_posthistory uph
    ON uph.user_id = u.id
LEFT JOIN user_tags ut
    ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
