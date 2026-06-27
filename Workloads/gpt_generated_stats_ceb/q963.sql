WITH
    badge_counts AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_counts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               SUM(score) AS total_post_score,
               AVG(score) AS avg_post_score,
               SUM(viewcount) AS total_viewcount,
               SUM(answercount) AS total_answercount,
               SUM(commentcount) AS total_commentcount,
               SUM(favoritecount) AS total_favoritecount
        FROM posts
        GROUP BY owneruserid
    ),
    edit_counts AS (
        SELECT lasteditoruserid AS userid,
               COUNT(*) AS edit_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    comment_counts AS (
        SELECT userid,
               COUNT(*) AS comment_count,
               SUM(score) AS total_comment_score,
               AVG(score) AS avg_comment_score
        FROM comments
        GROUP BY userid
    ),
    vote_counts AS (
        SELECT userid,
               COUNT(*) AS vote_cast_count,
               SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
               SUM(bountyamount) AS total_bounty_amount
        FROM votes
        GROUP BY userid
    ),
    posthistory_counts AS (
        SELECT userid,
               COUNT(*) AS posthistory_event_count
        FROM posthistory
        GROUP BY userid
    ),
    tag_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS distinct_tag_count,
               SUM(t.count) AS total_tag_usage
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    outgoing_links AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS outgoing_link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    incoming_links AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS incoming_link_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(pc.total_post_score, 0) AS total_post_score,
    COALESCE(pc.avg_post_score, 0) AS avg_post_score,
    COALESCE(pc.total_viewcount, 0) AS total_viewcount,
    COALESCE(pc.total_answercount, 0) AS total_answercount,
    COALESCE(pc.total_commentcount, 0) AS total_commentcount,
    COALESCE(pc.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(ec.edit_count, 0) AS edit_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(cc.total_comment_score, 0) AS total_comment_score,
    COALESCE(cc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vc.upvote_cast, 0) AS upvote_cast,
    COALESCE(vc.downvote_cast, 0) AS downvote_cast,
    COALESCE(vc.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(phc.posthistory_event_count, 0) AS posthistory_event_count,
    COALESCE(tc.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(tc.total_tag_usage, 0) AS total_tag_usage,
    COALESCE(ol.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(il.incoming_link_count, 0) AS incoming_link_count,
    (COALESCE(bc.badge_count, 0) + COALESCE(pc.post_count, 0) + COALESCE(cc.comment_count, 0) + COALESCE(vc.vote_cast_count, 0) + COALESCE(ec.edit_count, 0) + COALESCE(phc.posthistory_event_count, 0) + COALESCE(tc.distinct_tag_count, 0) + COALESCE(ol.outgoing_link_count, 0) + COALESCE(il.incoming_link_count, 0)) AS activity_score
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN post_counts pc ON pc.userid = u.id
LEFT JOIN edit_counts ec ON ec.userid = u.id
LEFT JOIN comment_counts cc ON cc.userid = u.id
LEFT JOIN vote_counts vc ON vc.userid = u.id
LEFT JOIN posthistory_counts phc ON phc.userid = u.id
LEFT JOIN tag_counts tc ON tc.userid = u.id
LEFT JOIN outgoing_links ol ON ol.userid = u.id
LEFT JOIN incoming_links il ON il.userid = u.id
ORDER BY activity_score DESC
LIMIT 10
