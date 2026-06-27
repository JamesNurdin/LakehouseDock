WITH owner_posts_agg AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(p.id) AS owned_post_count,
        SUM(p.score) AS owned_post_score_sum,
        AVG(p.viewcount) AS owned_post_avg_viewcount,
        SUM(p.commentcount) AS owned_post_total_commentcount,
        SUM(p.answercount) AS owned_post_total_answercount
    FROM posts p
    GROUP BY p.owneruserid
),

distinct_commenters_on_owned_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT c.userid) AS distinct_commenters_on_owned_posts
    FROM posts p
    JOIN comments c
        ON c.postid = p.id
    GROUP BY p.owneruserid
),

posthistory_on_owned_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(ph.id) AS posthistory_entries_on_owned_posts
    FROM posts p
    JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),

edited_posts_agg AS (
    SELECT
        p.lasteditoruserid AS userid,
        COUNT(p.id) AS edited_posts_count
    FROM posts p
    GROUP BY p.lasteditoruserid
),

user_comments_agg AS (
    SELECT
        c.userid AS userid,
        COUNT(c.id) AS user_comment_count,
        SUM(c.score) AS user_comment_score_sum
    FROM comments c
    GROUP BY c.userid
),

user_posthistory_actions AS (
    SELECT
        ph.userid AS userid,
        COUNT(ph.id) AS user_posthistory_action_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(op.owned_post_count, 0) AS owned_post_count,
    COALESCE(op.owned_post_score_sum, 0) AS owned_post_score_sum,
    COALESCE(op.owned_post_avg_viewcount, 0) AS owned_post_avg_viewcount,
    COALESCE(op.owned_post_total_commentcount, 0) AS owned_post_total_commentcount,
    COALESCE(op.owned_post_total_answercount, 0) AS owned_post_total_answercount,
    COALESCE(dc.distinct_commenters_on_owned_posts, 0) AS distinct_commenters_on_owned_posts,
    COALESCE(ph_own.posthistory_entries_on_owned_posts, 0) AS posthistory_entries_on_owned_posts,
    COALESCE(ep.edited_posts_count, 0) AS edited_posts_count,
    COALESCE(uc.user_comment_count, 0) AS user_comment_count,
    COALESCE(uc.user_comment_score_sum, 0) AS user_comment_score_sum,
    COALESCE(uph.user_posthistory_action_count, 0) AS user_posthistory_action_count
FROM users u
LEFT JOIN owner_posts_agg op
    ON op.userid = u.id
LEFT JOIN distinct_commenters_on_owned_posts dc
    ON dc.userid = u.id
LEFT JOIN posthistory_on_owned_posts ph_own
    ON ph_own.userid = u.id
LEFT JOIN edited_posts_agg ep
    ON ep.userid = u.id
LEFT JOIN user_comments_agg uc
    ON uc.userid = u.id
LEFT JOIN user_posthistory_actions uph
    ON uph.userid = u.id
ORDER BY owned_post_score_sum DESC
LIMIT 100
