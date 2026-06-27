WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        p.owneruserid AS owner_user_id,
        date_trunc('month', p.creationdate) AS month,
        p.score AS post_score,
        p.viewcount AS post_viewcount,
        p.answercount AS post_answercount,
        p.favoritecount AS post_favoritecount
    FROM posts p
    WHERE p.owneruserid IS NOT NULL
),
comment_counts AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_cnt
    FROM comments c
    GROUP BY c.postid
),
vote_counts AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt
    FROM votes v
    GROUP BY v.postid
),
owner_rep AS (
    SELECT
        u.id AS user_id,
        u.reputation AS reputation
    FROM users u
),
posthistory_agg AS (
    SELECT
        ph.userid AS user_id,
        date_trunc('month', ph.creationdate) AS month,
        COUNT(*) AS posthistory_events
    FROM posthistory ph
    GROUP BY ph.userid, date_trunc('month', ph.creationdate)
)
SELECT
    pm.owner_user_id,
    pm.month,
    COUNT(DISTINCT pm.post_id) AS posts_created,
    SUM(pm.post_score) AS total_post_score,
    AVG(pm.post_score) AS avg_post_score,
    SUM(pm.post_viewcount) AS total_views,
    SUM(pm.post_answercount) AS total_answers,
    SUM(pm.post_favoritecount) AS total_favorites,
    COALESCE(SUM(cc.comment_cnt), 0) AS total_comments_on_posts,
    COALESCE(SUM(vc.vote_cnt), 0) AS total_votes_on_posts,
    COALESCE(SUM(vc.upvote_cnt), 0) AS total_upvotes_on_posts,
    COALESCE(SUM(vc.downvote_cnt), 0) AS total_downvotes_on_posts,
    ur.reputation,
    COALESCE(phag.posthistory_events, 0) AS posthistory_events
FROM post_metrics pm
LEFT JOIN comment_counts cc
    ON cc.post_id = pm.post_id
LEFT JOIN vote_counts vc
    ON vc.post_id = pm.post_id
LEFT JOIN owner_rep ur
    ON ur.user_id = pm.owner_user_id
LEFT JOIN posthistory_agg phag
    ON phag.user_id = ur.user_id
   AND phag.month = pm.month
GROUP BY
    pm.owner_user_id,
    pm.month,
    ur.reputation,
    phag.posthistory_events
ORDER BY
    pm.owner_user_id,
    pm.month DESC
