WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_count,
        COUNT(DISTINCT userid) AS distinct_commenters
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_count,
        COUNT(DISTINCT userid) AS distinct_voters,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY postid
),
edit_agg AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
link_out_agg AS (
    SELECT
        postid,
        COUNT(*) AS link_out_count
    FROM postlinks
    GROUP BY postid
),
link_in_agg AS (
    SELECT
        relatedpostid,
        COUNT(*) AS link_in_count
    FROM postlinks
    GROUP BY relatedpostid
),
post_details AS (
    SELECT
        p.id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.owneruserid,
        u.reputation AS owner_reputation,
        u.creationdate AS owner_creationdate,
        u.views AS owner_views
    FROM posts p
    LEFT JOIN users u ON p.owneruserid = u.id
),
post_links AS (
    SELECT
        pd.id,
        COALESCE(lo.link_out_count, 0) AS link_out_count,
        COALESCE(li.link_in_count, 0) AS link_in_count
    FROM post_details pd
    LEFT JOIN link_out_agg lo ON lo.postid = pd.id
    LEFT JOIN link_in_agg li ON li.relatedpostid = pd.id
)
SELECT
    t.id AS tag_id,
    COUNT(DISTINCT pd.id) AS post_count,
    AVG(pd.score) AS avg_post_score,
    SUM(COALESCE(ca.comment_count, 0)) AS total_comments,
    SUM(COALESCE(va.vote_count, 0)) AS total_votes,
    SUM(COALESCE(va.upvote_count, 0)) AS total_upvotes,
    SUM(COALESCE(va.downvote_count, 0)) AS total_downvotes,
    AVG(COALESCE(pd.answercount, 0)) AS avg_answer_count,
    AVG(COALESCE(pd.owner_reputation, 0)) AS avg_owner_reputation,
    SUM(COALESCE(ea.edit_count, 0)) AS total_edits,
    SUM(COALESCE(pl.link_out_count, 0) + COALESCE(pl.link_in_count, 0)) AS total_links
FROM tags t
JOIN post_details pd ON t.excerptpostid = pd.id
LEFT JOIN comment_agg ca ON ca.postid = pd.id
LEFT JOIN vote_agg va ON va.postid = pd.id
LEFT JOIN edit_agg ea ON ea.postid = pd.id
LEFT JOIN post_links pl ON pl.id = pd.id
GROUP BY t.id
ORDER BY total_votes DESC
LIMIT 10
