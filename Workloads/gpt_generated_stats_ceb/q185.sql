WITH post_votes AS (
    SELECT postid,
           COUNT(*) AS vote_count
    FROM votes
    GROUP BY postid
),
post_commenters AS (
    SELECT postid,
           COUNT(DISTINCT userid) AS distinct_commenters
    FROM comments
    GROUP BY postid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_links AS (
    SELECT postid,
           COUNT(*) AS link_count
    FROM postlinks
    GROUP BY postid
),
post_history_counts AS (
    SELECT posthistorytypeid AS post_id,
           COUNT(*) AS history_event_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
tag_posts AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_total_posts,
        p.id AS post_id,
        p.owneruserid,
        p.score,
        p.commentcount,
        p.answercount,
        p.favoritecount,
        p.viewcount
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
)
SELECT
    tp.tag_id,
    tp.tag_total_posts,
    COUNT(tp.post_id) AS num_posts,
    SUM(tp.score) AS total_post_score,
    AVG(tp.score) AS avg_post_score,
    SUM(tp.commentcount) AS total_comments,
    AVG(tp.commentcount) AS avg_comments_per_post,
    SUM(COALESCE(pv.vote_count, 0)) AS total_votes,
    SUM(COALESCE(pl.link_count, 0)) AS total_post_links,
    SUM(COALESCE(ph.history_event_count, 0)) AS total_history_events,
    SUM(COALESCE(pc.distinct_commenters, 0)) AS total_distinct_commenters,
    COUNT(DISTINCT u.id) AS distinct_owner_users,
    SUM(COALESCE(ub.badge_count, 0)) AS total_owner_badges
FROM tag_posts tp
LEFT JOIN post_votes pv ON pv.postid = tp.post_id
LEFT JOIN post_links pl ON pl.postid = tp.post_id
LEFT JOIN post_history_counts ph ON ph.post_id = tp.post_id
LEFT JOIN post_commenters pc ON pc.postid = tp.post_id
JOIN users u ON tp.owneruserid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
GROUP BY tp.tag_id, tp.tag_total_posts
ORDER BY total_post_score DESC
LIMIT 20
