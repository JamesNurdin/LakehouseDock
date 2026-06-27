WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score AS post_score,
        p.viewcount,
        p.owneruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid,
        -- vote related aggregates
        COUNT(v.id) AS vote_count,
        SUM(v.votetypeid) AS vote_type_sum,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty,
        COUNT(DISTINCT v.userid) AS distinct_voter_count,
        -- comment related aggregates
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT c.userid) AS distinct_commenter_count,
        -- post‑link aggregates
        COUNT(pl.id) AS linked_post_count,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_related_post_count,
        -- post‑history aggregates (joined via posthistorytypeid per the allowed rule)
        COUNT(ph.id) AS posthistory_entry_count
    FROM posts p
    LEFT JOIN votes v       ON v.postid = p.id
    LEFT JOIN comments c    ON c.postid = p.id
    LEFT JOIN postlinks pl  ON pl.postid = p.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY
        p.id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.owneruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid
),
owner_info AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate AS user_creationdate,
        u.views AS user_views,
        u.upvotes AS user_upvotes,
        u.downvotes AS user_downvotes,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY
        u.id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
)
SELECT
    pm.post_id,
    pm.posttypeid,
    pm.creationdate,
    pm.post_score,
    pm.viewcount,
    pm.answercount,
    pm.commentcount,
    pm.favoritecount,
    pm.vote_count,
    pm.vote_type_sum,
    pm.total_bounty,
    pm.distinct_voter_count,
    pm.comment_count,
    pm.distinct_commenter_count,
    pm.linked_post_count,
    pm.distinct_related_post_count,
    pm.posthistory_entry_count,
    oi.reputation,
    oi.badge_count
FROM post_metrics pm
JOIN owner_info oi ON oi.user_id = pm.owneruserid
ORDER BY pm.vote_count DESC
LIMIT 10
