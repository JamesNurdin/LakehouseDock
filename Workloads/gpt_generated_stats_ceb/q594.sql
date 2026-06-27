WITH comments_agg AS (
    SELECT
        postid AS post_id,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
votes_agg AS (
    SELECT
        postid AS post_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(bountyamount) AS total_bounty
    FROM votes
    GROUP BY postid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid AS post_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
outgoing_links_agg AS (
    SELECT
        postid AS post_id,
        COUNT(*) AS outgoing_links
    FROM postlinks
    GROUP BY postid
),
incoming_links_agg AS (
    SELECT
        relatedpostid AS post_id,
        COUNT(*) AS incoming_links
    FROM postlinks
    GROUP BY relatedpostid
),
badges_agg AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount AS post_comment_count,
    p.favoritecount,
    p.owneruserid,
    u.reputation,
    u.upvotes,
    u.downvotes,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(va.vote_count, 0) AS vote_count,
    COALESCE(va.upvote_count, 0) AS upvote_count,
    COALESCE(va.downvote_count, 0) AS downvote_count,
    COALESCE(va.total_bounty, 0) AS total_bounty,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ol.outgoing_links, 0) + COALESCE(il.incoming_links, 0) AS total_links,
    COALESCE(b.badge_count, 0) AS owner_badge_count
FROM posts p
LEFT JOIN users u ON p.owneruserid = u.id
LEFT JOIN comments_agg ca ON p.id = ca.post_id
LEFT JOIN votes_agg va ON p.id = va.post_id
LEFT JOIN posthistory_agg ph ON p.id = ph.post_id
LEFT JOIN outgoing_links_agg ol ON p.id = ol.post_id
LEFT JOIN incoming_links_agg il ON p.id = il.post_id
LEFT JOIN badges_agg b ON u.id = b.userid
WHERE p.viewcount > 0
ORDER BY p.viewcount DESC
LIMIT 20
