SELECT
    u_owner.id AS owner_user_id,
    u_owner.reputation AS owner_reputation,
    COUNT(DISTINCT p.id) AS owned_post_count,
    COALESCE(SUM(p.viewcount), 0) AS total_viewcount_of_owned_posts,
    COALESCE(SUM(p.score), 0) AS total_score_of_owned_posts,
    COUNT(ph.id) AS total_posthistory_events_on_owned_posts,
    COUNT(DISTINCT ph.userid) AS distinct_event_user_count,
    COUNT(DISTINCT p.lasteditoruserid) AS distinct_last_editor_count,
    COALESCE(SUM(u_editor.reputation), 0) AS total_last_editor_reputation
FROM posthistory ph
JOIN posts p
    ON ph.posthistorytypeid = p.id
JOIN users u_owner
    ON p.owneruserid = u_owner.id
JOIN users u_event
    ON ph.userid = u_event.id
LEFT JOIN users u_editor
    ON p.lasteditoruserid = u_editor.id
GROUP BY u_owner.id, u_owner.reputation
ORDER BY total_posthistory_events_on_owned_posts DESC
LIMIT 50
