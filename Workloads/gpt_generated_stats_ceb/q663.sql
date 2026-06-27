WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(bountyamount) AS bounty_sum
    FROM votes
    GROUP BY postid
),
link_agg_source AS (
    SELECT
        postid,
        COUNT(*) AS outgoing_links
    FROM postlinks
    GROUP BY postid
),
link_agg_related AS (
    SELECT
        relatedpostid,
        COUNT(*) AS incoming_links
    FROM postlinks
    GROUP BY relatedpostid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid,
        COUNT(*) AS history_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
),
tag_agg AS (
    SELECT
        excerptpostid,
        COUNT(*) AS tag_cnt
    FROM tags
    GROUP BY excerptpostid
)
SELECT
    p.id,
    p.posttypeid,
    p.creationdate,
    p.owneruserid,
    p.score AS post_score,
    p.viewcount,
    COALESCE(ca.comment_cnt, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(va.vote_cnt, 0) AS vote_count,
    COALESCE(va.bounty_sum, 0) AS total_bounty,
    COALESCE(ls.outgoing_links, 0) AS outgoing_link_count,
    COALESCE(lr.incoming_links, 0) AS incoming_link_count,
    COALESCE(ha.history_cnt, 0) AS history_event_count,
    COALESCE(ta.tag_cnt, 0) AS tag_excerpt_count,
    (2 * p.score
     + p.viewcount
     + COALESCE(ca.comment_score_sum, 0)
     + 3 * COALESCE(va.vote_cnt, 0)
     + COALESCE(va.bounty_sum, 0)
     + 5 * (COALESCE(ls.outgoing_links, 0) + COALESCE(lr.incoming_links, 0))
     + 10 * COALESCE(ha.history_cnt, 0)
     + 4 * COALESCE(ta.tag_cnt, 0)
    ) AS engagement_score
FROM posts p
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN vote_agg va ON va.postid = p.id
LEFT JOIN link_agg_source ls ON ls.postid = p.id
LEFT JOIN link_agg_related lr ON lr.relatedpostid = p.id
LEFT JOIN posthistory_agg ha ON ha.posthistorytypeid = p.id
LEFT JOIN tag_agg ta ON ta.excerptpostid = p.id
ORDER BY engagement_score DESC
LIMIT 10
