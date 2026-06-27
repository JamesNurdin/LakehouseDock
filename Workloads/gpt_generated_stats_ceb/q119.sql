WITH owner_metrics AS (
    SELECT
        u_owner.id AS owner_id,
        u_owner.reputation AS owner_reputation,
        u_owner.creationdate AS owner_creationdate,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.score) AS total_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_commentcount,
        SUM(p.favoritecount) AS total_favoritecount,
        COUNT(DISTINCT u_editor.id) AS distinct_editor_count,
        COUNT(ph.id) AS posthistory_event_count,
        COUNT(DISTINCT u_actor.id) AS distinct_history_user_count
    FROM posts p
    LEFT JOIN users u_owner
        ON p.owneruserid = u_owner.id
    LEFT JOIN users u_editor
        ON p.lasteditoruserid = u_editor.id
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    LEFT JOIN users u_actor
        ON ph.userid = u_actor.id
    GROUP BY u_owner.id, u_owner.reputation, u_owner.creationdate
)
SELECT
    owner_id,
    owner_reputation,
    owner_creationdate,
    post_count,
    total_score,
    total_viewcount,
    total_answercount,
    total_commentcount,
    total_favoritecount,
    distinct_editor_count,
    posthistory_event_count,
    distinct_history_user_count,
    total_score / NULLIF(post_count, 0) AS avg_score_per_post,
    total_viewcount / NULLIF(post_count, 0) AS avg_viewcount_per_post,
    RANK() OVER (ORDER BY total_score DESC) AS score_rank
FROM owner_metrics
ORDER BY total_score DESC
LIMIT 10
