WITH vote_counts AS (
    SELECT postid, COUNT(*) AS vote_cnt
    FROM votes
    GROUP BY postid
),
comment_counts AS (
    SELECT postid, COUNT(*) AS comment_cnt
    FROM comments
    GROUP BY postid
),
owner_badge_counts AS (
    SELECT p.id AS post_id, COUNT(b.id) AS badge_cnt
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY p.id
),
post_edit_counts AS (
    SELECT posthistorytypeid AS post_id, COUNT(*) AS edit_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
),
outgoing_link_counts AS (
    SELECT postid AS post_id, COUNT(*) AS out_link_cnt
    FROM postlinks
    GROUP BY postid
),
incoming_link_counts AS (
    SELECT relatedpostid AS post_id, COUNT(*) AS in_link_cnt
    FROM postlinks
    GROUP BY relatedpostid
)
SELECT
    t.id AS tag_id,
    COUNT(DISTINCT p.id) AS total_posts,
    AVG(p.score) AS avg_post_score,
    SUM(COALESCE(vc.vote_cnt, 0)) AS total_votes,
    AVG(COALESCE(cc.comment_cnt, 0)) AS avg_comments_per_post,
    SUM(COALESCE(obc.badge_cnt, 0)) AS total_owner_badges,
    SUM(COALESCE(pec.edit_cnt, 0)) AS total_post_edits,
    SUM(COALESCE(olc.out_link_cnt, 0) + COALESCE(ilc.in_link_cnt, 0)) AS total_linked_posts
FROM tags t
LEFT JOIN posts p ON t.excerptpostid = p.id
LEFT JOIN vote_counts vc ON vc.postid = p.id
LEFT JOIN comment_counts cc ON cc.postid = p.id
LEFT JOIN owner_badge_counts obc ON obc.post_id = p.id
LEFT JOIN post_edit_counts pec ON pec.post_id = p.id
LEFT JOIN outgoing_link_counts olc ON olc.post_id = p.id
LEFT JOIN incoming_link_counts ilc ON ilc.post_id = p.id
GROUP BY t.id
ORDER BY total_posts DESC
LIMIT 10
