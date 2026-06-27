WITH joined AS (
    SELECT
        ph.id AS ph_id,
        ph.userid AS ph_userid,
        ph.creationdate AS ph_creationdate,
        ph.posthistorytypeid,
        p.id AS post_id,
        p.creationdate AS post_creationdate,
        p.score,
        p.owneruserid,
        p.lasteditoruserid,
        u_actor.reputation AS actor_reputation,
        u_owner.reputation AS owner_reputation,
        u_editor.reputation AS editor_reputation
    FROM posthistory ph
    JOIN posts p
        ON ph.posthistorytypeid = p.id
    JOIN users u_actor
        ON ph.userid = u_actor.id
    JOIN users u_owner
        ON p.owneruserid = u_owner.id
    LEFT JOIN users u_editor
        ON p.lasteditoruserid = u_editor.id
)
SELECT
    ph_userid AS user_id,
    actor_reputation,
    COUNT(ph_id) AS posthistory_actions,
    SUM(score) AS total_score_of_linked_posts,
    AVG(owner_reputation) AS avg_owner_reputation,
    COUNT(DISTINCT post_id) AS distinct_posts_linked,
    AVG(date_diff('day', ph_creationdate, post_creationdate)) AS avg_days_between_action_and_post,
    MAX(date_diff('day', ph_creationdate, post_creationdate)) AS max_days_gap
FROM joined
GROUP BY ph_userid, actor_reputation
ORDER BY posthistory_actions DESC
LIMIT 50
