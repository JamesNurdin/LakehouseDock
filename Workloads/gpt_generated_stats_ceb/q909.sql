WITH vote_agg AS (
    SELECT postid,
           COUNT(*) AS vote_count
    FROM votes
    GROUP BY postid
),
comment_agg AS (
    SELECT postid,
           COUNT(*) AS comment_count,
           COUNT(DISTINCT userid) AS distinct_commenters
    FROM comments
    GROUP BY postid
),
user_badge_agg AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
posthistory_agg AS (
    SELECT posthistorytypeid AS postid,
           COUNT(*) AS history_count
    FROM posthistory
    GROUP BY posthistorytypeid
)
SELECT
    t.id AS tag_id,
    t.count AS tag_post_count,
    COUNT(p.id) AS total_posts,
    SUM(p.score) AS total_post_score,
    SUM(p.viewcount) AS total_viewcount,
    SUM(p.answercount) AS total_answercount,
    SUM(p.commentcount) AS total_commentcount,
    SUM(COALESCE(v.vote_count, 0)) AS total_votes,
    SUM(COALESCE(c.comment_count, 0)) AS total_comments,
    SUM(COALESCE(c.distinct_commenters, 0)) AS total_distinct_commenters,
    SUM(COALESCE(ph.history_count, 0)) AS total_post_history_events,
    SUM(COALESCE(ub.badge_count, 0)) AS total_owner_badges,
    AVG(u.reputation) AS avg_owner_reputation
FROM tags t
JOIN posts p
    ON t.excerptpostid = p.id
JOIN users u
    ON p.owneruserid = u.id
LEFT JOIN vote_agg v
    ON p.id = v.postid
LEFT JOIN comment_agg c
    ON p.id = c.postid
LEFT JOIN posthistory_agg ph
    ON p.id = ph.postid
LEFT JOIN user_badge_agg ub
    ON u.id = ub.userid
GROUP BY t.id, t.count
ORDER BY total_posts DESC
LIMIT 20
