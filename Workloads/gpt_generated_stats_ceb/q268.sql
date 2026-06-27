WITH vote_counts AS (
        SELECT postid,
               COUNT(*) AS total_votes
        FROM votes
        GROUP BY postid
    ),
    comment_counts AS (
        SELECT postid,
               COUNT(*) AS total_comments
        FROM comments
        GROUP BY postid
    ),
    link_counts AS (
        SELECT postid,
               COUNT(*) AS total_links
        FROM postlinks
        GROUP BY postid
    ),
    history_counts AS (
        SELECT posthistorytypeid AS postid,
               COUNT(*) AS total_histories
        FROM posthistory
        GROUP BY posthistorytypeid
    ),
    owner_badges AS (
        SELECT userid,
               COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    )
SELECT
    t.id                     AS tag_id,
    t.count                  AS tag_count,
    p.id                     AS post_id,
    p.score                  AS post_score,
    p.viewcount              AS post_viewcount,
    p.answercount            AS post_answercount,
    p.commentcount           AS post_commentcount,
    COALESCE(vc.total_votes, 0)      AS total_votes,
    COALESCE(cc.total_comments, 0)   AS total_comments,
    COALESCE(lc.total_links, 0)      AS total_links,
    COALESCE(hc.total_histories, 0)  AS total_histories,
    u.reputation                     AS owner_reputation,
    COALESCE(ob.total_badges, 0)     AS owner_badge_count
FROM tags t
JOIN posts p ON t.excerptpostid = p.id
JOIN users u ON p.owneruserid = u.id
LEFT JOIN vote_counts vc ON vc.postid = p.id
LEFT JOIN comment_counts cc ON cc.postid = p.id
LEFT JOIN link_counts lc ON lc.postid = p.id
LEFT JOIN history_counts hc ON hc.postid = p.id
LEFT JOIN owner_badges ob ON ob.userid = u.id
ORDER BY t.id
