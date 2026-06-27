WITH post_agg AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score AS post_score,
        p.viewcount,
        p.owneruserid,
        p.lasteditoruserid,
        COUNT(DISTINCT c.id) AS comment_cnt,
        COUNT(DISTINCT v.id) AS vote_cnt,
        COUNT(DISTINCT ph.id) AS edit_cnt,
        COUNT(DISTINCT pl.id) AS link_cnt,
        COUNT(DISTINCT c.userid) AS distinct_commenters,
        COUNT(DISTINCT v.userid) AS distinct_voters,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_related_posts,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt,
        SUM(CASE WHEN v.votetypeid = 4 THEN COALESCE(v.bountyamount, 0) ELSE 0 END) AS total_bounty
    FROM posts p
    LEFT JOIN comments c ON c.postid = p.id
    LEFT JOIN votes v ON v.postid = p.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.id, p.posttypeid, p.creationdate, p.score, p.viewcount, p.owneruserid, p.lasteditoruserid
)
SELECT
    t.id AS tag_id,
    t.count AS tag_post_excerpt_count,
    COUNT(DISTINCT pa.post_id) AS num_posts,
    SUM(pa.post_score) AS total_post_score,
    AVG(pa.viewcount) AS avg_viewcount,
    SUM(pa.comment_cnt) AS total_comments,
    SUM(pa.vote_cnt) AS total_votes,
    SUM(pa.edit_cnt) AS total_edits,
    SUM(pa.link_cnt) AS total_links,
    COUNT(DISTINCT pa.owneruserid) AS distinct_owners,
    COUNT(DISTINCT pa.lasteditoruserid) AS distinct_last_editors,
    SUM(pa.upvote_cnt) AS total_upvotes,
    SUM(pa.downvote_cnt) AS total_downvotes,
    SUM(pa.total_bounty) AS total_bounty_awarded
FROM tags t
LEFT JOIN posts p ON p.id = t.excerptpostid
LEFT JOIN post_agg pa ON pa.post_id = p.id
GROUP BY t.id, t.count
ORDER BY total_post_score DESC
LIMIT 50
