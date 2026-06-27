WITH post_metrics AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        SUM(viewcount) AS total_views,
        SUM(favoritecount) AS total_fav,
        AVG(answercount) AS avg_answer_count
    FROM posts
    GROUP BY owneruserid
),
comment_metrics AS (
    SELECT
        userid,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
vote_cast_metrics AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
vote_received_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
edit_metrics AS (
    SELECT
        userid,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
tag_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.post_score_sum, 0) AS post_score_sum,
    COALESCE(pm.total_views, 0) AS total_views,
    COALESCE(pm.total_fav, 0) AS total_fav,
    COALESCE(pm.avg_answer_count, 0) AS avg_answer_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(vcm.votes_cast, 0) AS votes_cast,
    COALESCE(vrm.votes_received, 0) AS votes_received,
    COALESCE(em.edit_count, 0) AS edit_count,
    COALESCE(tm.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN post_metrics pm ON u.id = pm.owneruserid
LEFT JOIN comment_metrics cm ON u.id = cm.userid
LEFT JOIN vote_cast_metrics vcm ON u.id = vcm.userid
LEFT JOIN vote_received_metrics vrm ON u.id = vrm.user_id
LEFT JOIN edit_metrics em ON u.id = em.userid
LEFT JOIN tag_metrics tm ON u.id = tm.user_id
ORDER BY u.reputation DESC, post_count DESC
LIMIT 100
