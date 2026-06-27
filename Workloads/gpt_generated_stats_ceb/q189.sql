WITH
    post_comment_counts AS (
        SELECT
            p.id AS post_id,
            COUNT(c.id) AS comment_cnt,
            COALESCE(SUM(c.score), 0) AS comment_score_sum
        FROM posts p
        LEFT JOIN comments c ON c.postid = p.id
        GROUP BY p.id
    ),
    post_vote_counts AS (
        SELECT
            p.id AS post_id,
            COUNT(v.id) AS vote_cnt,
            COALESCE(SUM(v.bountyamount), 0) AS bounty_sum
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.id
    ),
    post_history_counts AS (
        SELECT
            p.id AS post_id,
            COUNT(ph.id) AS posthistory_cnt
        FROM posts p
        LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
        GROUP BY p.id
    ),
    post_link_counts AS (
        SELECT
            p.id AS post_id,
            COUNT(pl.id) AS postlink_cnt
        FROM posts p
        LEFT JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.id
    ),
    tag_commenter_counts AS (
        SELECT
            t.id AS tag_id,
            COUNT(DISTINCT c.userid) AS distinct_commenters
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        JOIN comments c ON c.postid = p.id
        GROUP BY t.id
    )
SELECT
    t.id AS tag_id,
    COUNT(DISTINCT p.id) AS post_cnt,
    AVG(p.score) AS avg_post_score,
    COALESCE(SUM(pc.comment_cnt), 0) AS total_comments,
    COALESCE(SUM(pv.vote_cnt), 0) AS total_votes,
    COALESCE(SUM(phc.posthistory_cnt), 0) AS total_posthistories,
    COALESCE(SUM(plc.postlink_cnt), 0) AS total_postlinks,
    AVG(u.reputation) AS avg_owner_reputation,
    COALESCE(cc.distinct_commenters, 0) AS distinct_commenters
FROM tags t
JOIN posts p ON t.excerptpostid = p.id
LEFT JOIN post_comment_counts pc ON pc.post_id = p.id
LEFT JOIN post_vote_counts pv ON pv.post_id = p.id
LEFT JOIN post_history_counts phc ON phc.post_id = p.id
LEFT JOIN post_link_counts plc ON plc.post_id = p.id
LEFT JOIN users u ON p.owneruserid = u.id
LEFT JOIN tag_commenter_counts cc ON cc.tag_id = t.id
GROUP BY t.id, cc.distinct_commenters
ORDER BY total_comments DESC
LIMIT 10
