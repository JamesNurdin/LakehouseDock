WITH
    post_vote_agg AS (
        SELECT
            postid,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
        FROM votes
        GROUP BY postid
    ),
    comment_agg AS (
        SELECT
            postid,
            COUNT(*) AS comment_count,
            COUNT(DISTINCT userid) AS distinct_commenters
        FROM comments
        GROUP BY postid
    ),
    owner_badge_agg AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    postlink_out_agg AS (
        SELECT
            postid,
            COUNT(*) AS outgoing_link_count
        FROM postlinks
        GROUP BY postid
    ),
    postlink_in_agg AS (
        SELECT
            relatedpostid AS postid,
            COUNT(*) AS incoming_link_count
        FROM postlinks
        GROUP BY relatedpostid
    ),
    tag_agg AS (
        SELECT
            excerptpostid AS postid,
            COUNT(*) AS tag_count
        FROM tags
        GROUP BY excerptpostid
    ),
    post_history_agg AS (
        SELECT
            posthistorytypeid AS postid,
            COUNT(*) AS history_count
        FROM posthistory
        GROUP BY posthistorytypeid
    )
SELECT
    p.id AS post_id,
    p.creationdate,
    p.score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    u.reputation AS owner_reputation,
    u.upvotes AS owner_upvotes,
    u.downvotes AS owner_downvotes,
    COALESCE(v.vote_count, 0) AS total_votes,
    COALESCE(v.upvote_count, 0) AS upvotes_on_post,
    COALESCE(v.downvote_count, 0) AS downvotes_on_post,
    COALESCE(c.comment_count, 0) AS total_comments,
    COALESCE(c.distinct_commenters, 0) AS distinct_commenters,
    COALESCE(b.badge_count, 0) AS owner_badge_count,
    COALESCE(t.tag_count, 0) AS excerpt_tag_count,
    COALESCE(h.history_count, 0) AS post_history_count,
    COALESCE(plo.outgoing_link_count, 0) AS outgoing_links,
    COALESCE(pli.incoming_link_count, 0) AS incoming_links
FROM posts p
LEFT JOIN users u ON u.id = p.owneruserid
LEFT JOIN post_vote_agg v ON v.postid = p.id
LEFT JOIN comment_agg c ON c.postid = p.id
LEFT JOIN owner_badge_agg b ON b.userid = u.id
LEFT JOIN postlink_out_agg plo ON plo.postid = p.id
LEFT JOIN postlink_in_agg pli ON pli.postid = p.id
LEFT JOIN tag_agg t ON t.postid = p.id
LEFT JOIN post_history_agg h ON h.postid = p.id
ORDER BY total_votes DESC, p.creationdate DESC
LIMIT 20
