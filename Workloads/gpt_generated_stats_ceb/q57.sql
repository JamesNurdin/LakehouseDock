WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS post_score_sum,
        COALESCE(AVG(p.score), 0) AS post_score_avg,
        COALESCE(SUM(p.viewcount), 0) AS post_viewcount_sum,
        COALESCE(SUM(p.answercount), 0) AS post_answercount_sum,
        COALESCE(SUM(p.commentcount), 0) AS post_commentcount_sum,
        COALESCE(SUM(p.favoritecount), 0) AS post_favoritecount_sum
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum,
        COALESCE(AVG(c.score), 0) AS comment_score_avg
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_given_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_given_count,
        COALESCE(SUM(v.bountyamount), 0) AS bounty_given_sum
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count,
        MIN(b.date) AS first_badge_date,
        MAX(b.date) AS last_badge_date
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
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
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS total_posts,
    ROW_NUMBER() OVER (ORDER BY COALESCE(up.post_count, 0) DESC) AS post_rank,
    COALESCE(up.post_score_sum, 0) AS total_post_score,
    COALESCE(up.post_score_avg, 0) AS avg_post_score,
    COALESCE(up.post_viewcount_sum, 0) AS total_post_viewcount,
    COALESCE(up.post_answercount_sum, 0) AS total_post_answercount,
    COALESCE(up.post_commentcount_sum, 0) AS total_post_commentcount,
    COALESCE(up.post_favoritecount_sum, 0) AS total_post_favoritecount,
    COALESCE(uc.comment_count, 0) AS total_comments,
    COALESCE(uc.comment_score_sum, 0) AS total_comment_score,
    COALESCE(uc.comment_score_avg, 0) AS avg_comment_score,
    COALESCE(uv.vote_count, 0) AS total_votes_given,
    COALESCE(uv.upvote_given_count, 0) AS upvotes_given,
    COALESCE(uv.downvote_given_count, 0) AS downvotes_given,
    COALESCE(uv.bounty_given_sum, 0) AS total_bounty_given,
    COALESCE(ub.badge_count, 0) AS total_badges,
    ub.first_badge_date,
    ub.last_badge_date,
    COALESCE(ue.edited_post_count, 0) AS posts_edited,
    COALESCE(uph.posthistory_count, 0) AS posthistory_entries
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_comments uc
    ON uc.user_id = u.id
LEFT JOIN user_votes uv
    ON uv.user_id = u.id
LEFT JOIN user_badges ub
    ON ub.user_id = u.id
LEFT JOIN user_edits ue
    ON ue.user_id = u.id
LEFT JOIN user_posthistory uph
    ON uph.user_id = u.id
ORDER BY total_posts DESC
LIMIT 100
