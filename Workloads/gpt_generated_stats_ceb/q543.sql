WITH comment_agg AS (
    SELECT postid,
           COUNT(*) AS comment_cnt,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT postid,
           COUNT(*) AS vote_cnt,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cnt,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cnt,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS closevote_cnt,
           SUM(CASE WHEN votetypeid = 4 THEN 1 ELSE 0 END) AS deletevote_cnt,
           SUM(CASE WHEN votetypeid = 5 THEN 1 ELSE 0 END) AS undeletevote_cnt,
           SUM(CASE WHEN votetypeid = 6 THEN 1 ELSE 0 END) AS reopenvote_cnt,
           SUM(CASE WHEN votetypeid = 7 THEN 1 ELSE 0 END) AS bounty_start_cnt,
           SUM(CASE WHEN votetypeid = 8 THEN 1 ELSE 0 END) AS bounty_close_cnt,
           SUM(CASE WHEN votetypeid = 9 THEN 1 ELSE 0 END) AS delete_vote_cnt,
           SUM(bountyamount) AS total_bounty_amount
    FROM votes
    GROUP BY postid
),
postlink_outbound_agg AS (
    SELECT postid,
           COUNT(*) AS outbound_link_cnt
    FROM postlinks
    GROUP BY postid
),
postlink_inbound_agg AS (
    SELECT relatedpostid,
           COUNT(*) AS inbound_link_cnt
    FROM postlinks
    GROUP BY relatedpostid
),
posthistory_agg AS (
    SELECT posthistorytypeid,
           COUNT(*) AS posthistory_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
),
tag_agg AS (
    SELECT excerptpostid,
           COUNT(*) AS tag_cnt,
           SUM(count) AS tag_total_count
    FROM tags
    GROUP BY excerptpostid
)
SELECT p.id,
       p.posttypeid,
       p.creationdate,
       p.score,
       p.viewcount,
       p.owneruserid,
       p.answercount,
       p.commentcount,
       p.favoritecount,
       COALESCE(ca.comment_cnt, 0) AS comment_cnt,
       COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(va.vote_cnt, 0) AS vote_cnt,
       COALESCE(va.upvote_cnt, 0) AS upvote_cnt,
       COALESCE(va.downvote_cnt, 0) AS downvote_cnt,
       COALESCE(va.total_bounty_amount, 0) AS total_bounty_amount,
       COALESCE(pl_out.outbound_link_cnt, 0) AS outbound_link_cnt,
       COALESCE(pl_in.inbound_link_cnt, 0) AS inbound_link_cnt,
       COALESCE(ph.posthistory_cnt, 0) AS posthistory_cnt,
       COALESCE(tg.tag_cnt, 0) AS tag_cnt,
       COALESCE(tg.tag_total_count, 0) AS tag_total_count,
       -- Derived engagement metric
       (p.score * 2 +
        COALESCE(ca.comment_cnt, 0) * 1 +
        COALESCE(va.vote_cnt, 0) * 1 +
        p.viewcount / 100.0) AS engagement_score
FROM posts p
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN vote_agg va ON va.postid = p.id
LEFT JOIN postlink_outbound_agg pl_out ON pl_out.postid = p.id
LEFT JOIN postlink_inbound_agg pl_in ON pl_in.relatedpostid = p.id
LEFT JOIN posthistory_agg ph ON ph.posthistorytypeid = p.id
LEFT JOIN tag_agg tg ON tg.excerptpostid = p.id
WHERE p.posttypeid = 1
ORDER BY engagement_score DESC
LIMIT 100
