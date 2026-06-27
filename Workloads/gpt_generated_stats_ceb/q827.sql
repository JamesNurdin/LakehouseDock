-- Monthly activity summary for the selected Stack Exchange dataset
WITH post_months AS (
    SELECT
        id AS post_id,
        date_trunc('month', creationdate) AS month,
        score AS post_score,
        owneruserid
    FROM posts
),
comments_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
votes_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_count
    FROM votes
    GROUP BY postid
),
tags_agg AS (
    SELECT
        excerptpostid AS postid,
        COUNT(*) AS tag_count
    FROM tags
    GROUP BY excerptpostid
),
postlinks_out_agg AS (
    SELECT
        postid,
        COUNT(*) AS outlink_count
    FROM postlinks
    GROUP BY postid
),
postlinks_in_agg AS (
    SELECT
        relatedpostid AS postid,
        COUNT(*) AS inlink_count
    FROM postlinks
    GROUP BY relatedpostid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
owner_badges_agg AS (
    SELECT
        u.id AS owner_user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
)
SELECT
    pm.month,
    COUNT(DISTINCT pm.post_id) AS total_posts,
    AVG(pm.post_score) AS avg_post_score,
    COALESCE(SUM(ca.comment_count), 0) AS total_comments,
    CASE
        WHEN COALESCE(SUM(ca.comment_count), 0) = 0 THEN NULL
        ELSE CAST(SUM(ca.comment_score_sum) AS double) / SUM(ca.comment_count)
    END AS avg_comment_score,
    COALESCE(SUM(va.vote_count), 0) AS total_votes,
    COALESCE(SUM(ta.tag_count), 0) AS total_tags,
    COALESCE(SUM(plo.outlink_count), 0) AS total_outgoing_links,
    COALESCE(SUM(pli.inlink_count), 0) AS total_incoming_links,
    COALESCE(SUM(ph.posthistory_count), 0) AS total_posthistory_entries,
    COALESCE(SUM(ob.badge_count), 0) AS total_badges_earned_by_owners
FROM post_months pm
LEFT JOIN comments_agg ca
    ON ca.postid = pm.post_id
LEFT JOIN votes_agg va
    ON va.postid = pm.post_id
LEFT JOIN tags_agg ta
    ON ta.postid = pm.post_id
LEFT JOIN postlinks_out_agg plo
    ON plo.postid = pm.post_id
LEFT JOIN postlinks_in_agg pli
    ON pli.postid = pm.post_id
LEFT JOIN posthistory_agg ph
    ON ph.postid = pm.post_id
LEFT JOIN owner_badges_agg ob
    ON ob.owner_user_id = pm.owneruserid
GROUP BY pm.month
ORDER BY pm.month
