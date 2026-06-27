WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum,
        COUNT(DISTINCT userid) AS distinct_comment_user_count
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(bountyamount) AS bounty_sum
    FROM votes
    GROUP BY postid
),
tag_agg AS (
    SELECT
        excerptpostid AS postid,
        COUNT(*) AS tag_count
    FROM tags
    GROUP BY excerptpostid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS history_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
badge_agg AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
postlinks_out AS (
    SELECT
        postid AS post_id,
        COUNT(*) AS outgoing_link_count
    FROM postlinks
    GROUP BY postid
),
postlinks_in AS (
    SELECT
        relatedpostid AS post_id,
        COUNT(*) AS incoming_link_count
    FROM postlinks
    GROUP BY relatedpostid
),
postlinks_agg AS (
    SELECT
        COALESCE(o.post_id, i.post_id) AS post_id,
        COALESCE(o.outgoing_link_count, 0) AS outgoing_link_count,
        COALESCE(i.incoming_link_count, 0) AS incoming_link_count
    FROM postlinks_out o
    FULL OUTER JOIN postlinks_in i ON o.post_id = i.post_id
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.owneruserid,
    u.reputation AS owner_reputation,
    COALESCE(b.badge_count, 0) AS owner_badge_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(c.distinct_comment_user_count, 0) AS distinct_comment_user_count,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(v.bounty_sum, 0) AS bounty_sum,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(ph.history_count, 0) AS posthistory_count,
    COALESCE(pl.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(pl.incoming_link_count, 0) AS incoming_link_count,
    COALESCE(pl.outgoing_link_count, 0) + COALESCE(pl.incoming_link_count, 0) AS total_link_count
FROM posts p
LEFT JOIN users u ON p.owneruserid = u.id
LEFT JOIN badge_agg b ON b.userid = u.id
LEFT JOIN comment_agg c ON c.postid = p.id
LEFT JOIN vote_agg v ON v.postid = p.id
LEFT JOIN tag_agg t ON t.postid = p.id
LEFT JOIN posthistory_agg ph ON ph.postid = p.id
LEFT JOIN postlinks_agg pl ON pl.post_id = p.id
WHERE p.posttypeid = 1
ORDER BY p.creationdate DESC
LIMIT 100
