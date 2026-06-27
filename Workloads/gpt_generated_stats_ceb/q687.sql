WITH post_agg AS (
    SELECT
        p.id AS post_id,
        p.owneruserid,
        p.score,
        p.viewcount,
        p.commentcount,
        COUNT(DISTINCT v.id) AS vote_count,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT ph.id) AS posthistory_count,
        COUNT(DISTINCT pl_out.id) AS outgoing_link_count,
        COUNT(DISTINCT pl_in.id) AS incoming_link_count
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    LEFT JOIN comments c ON c.postid = p.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    LEFT JOIN postlinks pl_out ON pl_out.postid = p.id
    LEFT JOIN postlinks pl_in ON pl_in.relatedpostid = p.id
    GROUP BY
        p.id,
        p.owneruserid,
        p.score,
        p.viewcount,
        p.commentcount
)
SELECT
    t.id AS tag_id,
    t.count AS tag_usage_count,
    COUNT(DISTINCT pa.post_id) AS total_posts,
    SUM(pa.viewcount) AS total_viewcount,
    AVG(pa.score) AS avg_score,
    SUM(pa.comment_count) AS total_comments,
    SUM(pa.vote_count) AS total_votes,
    SUM(pa.posthistory_count) AS total_posthistory_events,
    SUM(pa.outgoing_link_count + pa.incoming_link_count) AS total_links,
    COUNT(DISTINCT u.id) AS distinct_owner_count,
    AVG(u.reputation) AS avg_owner_reputation,
    COALESCE(SUM(bc.badge_count), 0) AS total_owner_badges
FROM tags t
JOIN post_agg pa ON t.excerptpostid = pa.post_id
JOIN users u ON pa.owneruserid = u.id
LEFT JOIN (
    SELECT
        b.userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
) bc ON bc.userid = u.id
GROUP BY
    t.id,
    t.count
ORDER BY total_viewcount DESC
LIMIT 10
