WITH post_comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        COALESCE(SUM(score), 0) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
post_vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        COALESCE(SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cnt,
        COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cnt,
        COALESCE(SUM(CASE WHEN votetypeid = 3 THEN bountyamount ELSE 0 END), 0) AS bounty_sum
    FROM votes
    GROUP BY postid
),
owner_badge_agg AS (
    SELECT
        userid,
        COUNT(*) AS badge_cnt
    FROM badges
    GROUP BY userid
),
post_history_agg AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS history_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
),
post_link_agg AS (
    SELECT
        postid,
        COUNT(*) AS link_cnt
    FROM postlinks
    GROUP BY postid
)
SELECT
    t.id AS tag_id,
    COUNT(DISTINCT p.id) AS tag_post_count,
    COALESCE(SUM(p.score), 0) AS total_post_score,
    COALESCE(SUM(COALESCE(pc.comment_cnt, 0)), 0) AS total_comment_count,
    COALESCE(SUM(COALESCE(pc.comment_score_sum, 0)), 0) AS total_comment_score,
    COALESCE(SUM(COALESCE(pv.vote_cnt, 0)), 0) AS total_vote_count,
    COALESCE(SUM(COALESCE(pv.upvote_cnt, 0)), 0) AS total_upvote_count,
    COALESCE(SUM(COALESCE(pv.downvote_cnt, 0)), 0) AS total_downvote_count,
    COALESCE(AVG(u.reputation), 0) AS avg_owner_reputation,
    COALESCE(SUM(COALESCE(ob.badge_cnt, 0)), 0) AS total_owner_badge_count,
    COALESCE(SUM(COALESCE(ph.history_cnt, 0)), 0) AS total_history_count,
    COALESCE(SUM(COALESCE(pl.link_cnt, 0)), 0) AS total_link_count
FROM tags t
JOIN posts p
    ON t.excerptpostid = p.id
LEFT JOIN post_comment_agg pc
    ON p.id = pc.postid
LEFT JOIN post_vote_agg pv
    ON p.id = pv.postid
JOIN users u
    ON p.owneruserid = u.id
LEFT JOIN owner_badge_agg ob
    ON u.id = ob.userid
LEFT JOIN post_history_agg ph
    ON p.id = ph.postid
LEFT JOIN post_link_agg pl
    ON p.id = pl.postid
GROUP BY t.id
ORDER BY total_post_score DESC
LIMIT 20
