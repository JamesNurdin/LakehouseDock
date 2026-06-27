WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation AS user_reputation,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast,
        COUNT(DISTINCT v.postid) AS distinct_posts_voted
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count,
        COUNT(DISTINCT ph.posthistorytypeid) AS distinct_posts_edited,
        AVG(p.score) AS avg_score_of_edited_posts,
        COUNT(DISTINCT t.id) AS distinct_tags_of_edited_posts
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.user_reputation,
    up.post_count,
    up.total_score,
    up.total_views,
    uv.votes_cast,
    uv.distinct_posts_voted,
    ue.edit_count,
    ue.distinct_posts_edited,
    ue.avg_score_of_edited_posts,
    ue.distinct_tags_of_edited_posts
FROM user_posts up
LEFT JOIN user_votes uv
    ON up.user_id = uv.user_id
LEFT JOIN user_edits ue
    ON up.user_id = ue.user_id
ORDER BY up.total_score DESC
LIMIT 10
