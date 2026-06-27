WITH badge_counts AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
posthistory_counts AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS post_history_count
    FROM posthistory ph
    GROUP BY ph.userid
),
vote_metrics AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_given,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_given,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_given
    FROM votes v
    GROUP BY v.userid
),
user_base AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
)
SELECT
    ub.user_id,
    ub.reputation,
    year(ub.creationdate) AS creation_year,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(phc.post_history_count, 0) AS post_history_count,
    COALESCE(vm.vote_count, 0) AS vote_count,
    COALESCE(vm.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(vm.upvote_given, 0) AS upvote_given,
    COALESCE(vm.downvote_given, 0) AS downvote_given,
    (COALESCE(bc.badge_count, 0) + COALESCE(phc.post_history_count, 0) + COALESCE(vm.vote_count, 0)) AS total_activity
FROM user_base ub
LEFT JOIN badge_counts bc   ON bc.user_id = ub.user_id
LEFT JOIN posthistory_counts phc ON phc.user_id = ub.user_id
LEFT JOIN vote_metrics vm   ON vm.user_id = ub.user_id
ORDER BY total_activity DESC
LIMIT 100
