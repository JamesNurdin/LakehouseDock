WITH post_metrics AS (
    SELECT
        p.posttypeid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments,
        SUM(p.favoritecount) AS total_favorites,
        COUNT(DISTINCT p.owneruserid) AS distinct_owner_count,
        AVG(o.reputation) AS avg_owner_reputation,
        COUNT(DISTINCT p.lasteditoruserid) AS distinct_editor_count,
        AVG(e.reputation) AS avg_editor_reputation
    FROM posts p
    LEFT JOIN users o ON p.owneruserid = o.id
    LEFT JOIN users e ON p.lasteditoruserid = e.id
    GROUP BY p.posttypeid
),
vote_metrics AS (
    SELECT
        p.posttypeid,
        COUNT(v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(v.bountyamount) AS total_bounty,
        COUNT(DISTINCT v.userid) AS distinct_voter_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.posttypeid
),
history_metrics AS (
    SELECT
        p.posttypeid,
        COUNT(ph.id) AS posthistory_event_count,
        COUNT(DISTINCT ph.userid) AS distinct_history_user_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.posttypeid
)
SELECT
    pm.posttypeid,
    pm.post_count,
    pm.total_score,
    pm.avg_score,
    pm.total_views,
    pm.total_answers,
    pm.total_comments,
    pm.total_favorites,
    pm.distinct_owner_count,
    pm.avg_owner_reputation,
    pm.distinct_editor_count,
    pm.avg_editor_reputation,
    vm.vote_count,
    vm.upvote_count,
    vm.downvote_count,
    vm.total_bounty,
    vm.distinct_voter_count,
    hm.posthistory_event_count,
    hm.distinct_history_user_count
FROM post_metrics pm
LEFT JOIN vote_metrics vm ON pm.posttypeid = vm.posttypeid
LEFT JOIN history_metrics hm ON pm.posttypeid = hm.posttypeid
ORDER BY pm.posttypeid
