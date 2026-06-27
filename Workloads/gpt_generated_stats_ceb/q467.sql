WITH vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN bountyamount IS NOT NULL THEN bountyamount ELSE 0 END) AS total_bounty
    FROM votes
    GROUP BY postid
),
link_out_agg AS (
    SELECT
        postid,
        COUNT(*) AS out_link_cnt,
        COUNT(DISTINCT relatedpostid) AS distinct_out_links,
        COUNT(CASE WHEN linktypeid = 1 THEN 1 END) AS linktype1_cnt
    FROM postlinks
    GROUP BY postid
),
link_in_agg AS (
    SELECT
        relatedpostid AS postid,
        COUNT(*) AS in_link_cnt,
        COUNT(DISTINCT postid) AS distinct_in_links
    FROM postlinks
    GROUP BY relatedpostid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score,
    RANK() OVER (PARTITION BY p.posttypeid ORDER BY p.score DESC) AS score_rank,
    p.viewcount,
    p.owneruserid,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    COALESCE(v.vote_cnt, 0) AS total_votes,
    COALESCE(v.total_bounty, 0) AS total_bounty_amount,
    COALESCE(lo.out_link_cnt, 0) AS outgoing_links,
    COALESCE(li.in_link_cnt, 0) AS incoming_links,
    COALESCE(lo.linktype1_cnt, 0) AS linktype1_outgoing
FROM posts p
LEFT JOIN vote_agg v ON v.postid = p.id
LEFT JOIN link_out_agg lo ON lo.postid = p.id
LEFT JOIN link_in_agg li ON li.postid = p.id
ORDER BY p.creationdate DESC
LIMIT 100
