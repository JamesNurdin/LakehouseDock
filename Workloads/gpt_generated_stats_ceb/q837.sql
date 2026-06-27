WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        p.owneruserid,
        p.score AS post_score,
        COALESCE(v.vote_count, 0) AS vote_count,
        COALESCE(c.comment_count, 0) AS comment_count,
        COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
        COALESCE(t.tag_count, 0) AS tag_count,
        COALESCE(pl.link_count, 0) AS link_count
    FROM posts p
    LEFT JOIN (
        SELECT postid, COUNT(*) AS vote_count
        FROM votes
        GROUP BY postid
    ) v ON v.postid = p.id
    LEFT JOIN (
        SELECT postid,
               COUNT(*) AS comment_count,
               AVG(score) AS avg_comment_score
        FROM comments
        GROUP BY postid
    ) c ON c.postid = p.id
    LEFT JOIN (
        SELECT excerptpostid, COUNT(*) AS tag_count
        FROM tags
        GROUP BY excerptpostid
    ) t ON t.excerptpostid = p.id
    LEFT JOIN (
        SELECT postid, SUM(cnt) AS link_count
        FROM (
            SELECT postid, COUNT(*) AS cnt
            FROM postlinks
            GROUP BY postid
            UNION ALL
            SELECT relatedpostid AS postid, COUNT(*) AS cnt
            FROM postlinks
            GROUP BY relatedpostid
        ) sub
        GROUP BY postid
    ) pl ON pl.postid = p.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(DISTINCT pm.post_id) AS num_posts,
    SUM(pm.post_score) AS total_post_score,
    SUM(pm.vote_count) AS total_votes_received,
    SUM(pm.comment_count) AS total_comments_on_posts,
    AVG(pm.avg_comment_score) AS avg_comment_score_on_posts,
    SUM(pm.tag_count) AS total_tags_on_posts,
    SUM(pm.link_count) AS total_links_on_posts,
    COALESCE(b.badge_count, 0) AS total_badges,
    COALESCE(ph.edit_count, 0) AS total_edits_made
FROM users u
LEFT JOIN (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
) b ON b.userid = u.id
LEFT JOIN (
    SELECT userid, COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
) ph ON ph.userid = u.id
LEFT JOIN post_metrics pm ON pm.owneruserid = u.id
GROUP BY u.id, u.reputation, b.badge_count, ph.edit_count
ORDER BY total_post_score DESC
LIMIT 100
