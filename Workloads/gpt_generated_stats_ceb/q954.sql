WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum,
        COUNT(DISTINCT userid) AS distinct_comment_user_cnt
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt,
        COUNT(DISTINCT userid) AS distinct_voter_user_cnt
    FROM votes
    GROUP BY postid
),
badge_user_agg AS (
    SELECT
        p.id AS post_id,
        COUNT(DISTINCT b.userid) AS badge_user_cnt
    FROM posts p
    JOIN comments c ON c.postid = p.id
    JOIN users u ON c.userid = u.id
    JOIN badges b ON b.userid = u.id
    GROUP BY p.id
),
post_user_agg AS (
    SELECT
        p.id AS post_id,
        COUNT(DISTINCT COALESCE(p.owneruserid, p.lasteditoruserid)) AS distinct_owner_editor_user_cnt
    FROM posts p
    GROUP BY p.id
),
postlink_out_agg AS (
    SELECT
        postid,
        COUNT(*) AS outbound_link_cnt
    FROM postlinks
    GROUP BY postid
),
postlink_in_agg AS (
    SELECT
        relatedpostid AS post_id,
        COUNT(*) AS inbound_link_cnt
    FROM postlinks
    GROUP BY relatedpostid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid AS post_id,
        COUNT(*) AS edit_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
)
SELECT
    t.id AS tag_id,
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    COALESCE(ca.comment_cnt, 0) AS total_comments,
    COALESCE(ca.comment_score_sum, 0) AS total_comment_score,
    COALESCE(ca.distinct_comment_user_cnt, 0) AS distinct_comment_user_cnt,
    COALESCE(va.vote_cnt, 0) AS total_votes,
    COALESCE(va.upvote_cnt, 0) AS total_upvotes,
    COALESCE(va.downvote_cnt, 0) AS total_downvotes,
    COALESCE(va.distinct_voter_user_cnt, 0) AS distinct_voter_user_cnt,
    COALESCE(pu.distinct_owner_editor_user_cnt, 0) AS distinct_owner_editor_user_cnt,
    COALESCE(bu.badge_user_cnt, 0) AS badge_user_cnt,
    COALESCE(pl_out.outbound_link_cnt, 0) AS outbound_link_cnt,
    COALESCE(pl_in.inbound_link_cnt, 0) AS inbound_link_cnt,
    COALESCE(ph.edit_cnt, 0) AS edit_cnt
FROM tags t
JOIN posts p ON t.excerptpostid = p.id
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN vote_agg va ON va.postid = p.id
LEFT JOIN post_user_agg pu ON pu.post_id = p.id
LEFT JOIN badge_user_agg bu ON bu.post_id = p.id
LEFT JOIN postlink_out_agg pl_out ON pl_out.postid = p.id
LEFT JOIN postlink_in_agg pl_in ON pl_in.post_id = p.id
LEFT JOIN posthistory_agg ph ON ph.post_id = p.id
ORDER BY p.score DESC
LIMIT 100
