WITH tag_post AS (
    SELECT
        t.id AS tag_id,
        p.id AS post_id,
        p.owneruserid,
        p.score,
        p.viewcount
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
),
comment_counts AS (
    SELECT postid, COUNT(*) AS comment_cnt
    FROM comments
    GROUP BY postid
),
vote_counts AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt
    FROM votes
    GROUP BY postid
),
badge_counts AS (
    SELECT u.id AS userid, COUNT(b.id) AS badge_cnt
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
link_counts AS (
    SELECT postid, COUNT(*) AS link_cnt
    FROM postlinks
    GROUP BY postid
),
history_counts AS (
    SELECT posthistorytypeid AS post_id, COUNT(*) AS history_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
)
SELECT
    tp.tag_id,
    COUNT(DISTINCT tp.post_id) AS post_count,
    SUM(tp.score) AS total_score,
    AVG(tp.viewcount) AS avg_viewcount,
    SUM(COALESCE(cc.comment_cnt, 0)) AS total_comments,
    SUM(COALESCE(vc.vote_cnt, 0)) AS total_votes,
    SUM(COALESCE(vc.upvote_cnt, 0)) AS total_upvotes,
    SUM(COALESCE(vc.downvote_cnt, 0)) AS total_downvotes,
    SUM(COALESCE(bc.badge_cnt, 0)) AS total_owner_badges,
    SUM(COALESCE(lc.link_cnt, 0)) AS total_links,
    SUM(COALESCE(hc.history_cnt, 0)) AS total_history_entries
FROM tag_post tp
LEFT JOIN comment_counts cc ON cc.postid = tp.post_id
LEFT JOIN vote_counts vc ON vc.postid = tp.post_id
LEFT JOIN badge_counts bc ON bc.userid = tp.owneruserid
LEFT JOIN link_counts lc ON lc.postid = tp.post_id
LEFT JOIN history_counts hc ON hc.post_id = tp.post_id
GROUP BY tp.tag_id
ORDER BY total_score DESC
LIMIT 10
