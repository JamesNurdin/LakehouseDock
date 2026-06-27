WITH
    post_votes AS (
        SELECT
            postid,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
            COALESCE(SUM(bountyamount), 0) AS bounty_total
        FROM votes
        GROUP BY postid
    ),
    post_links AS (
        SELECT
            postid,
            COUNT(*) AS link_count
        FROM postlinks
        GROUP BY postid
    ),
    post_hist_by_post AS (
        SELECT
            posthistorytypeid AS post_id,
            COUNT(*) AS history_event_count
        FROM posthistory
        GROUP BY posthistorytypeid
    ),
    owner_post_metrics AS (
        SELECT
            p.owneruserid AS owner_user_id,
            COUNT(p.id) AS total_posts,
            AVG(p.score) AS avg_post_score,
            AVG(p.answercount) AS avg_answer_count,
            AVG(p.commentcount) AS avg_comment_count,
            SUM(COALESCE(v.vote_count, 0)) AS total_votes,
            SUM(COALESCE(v.upvote_count, 0)) AS total_upvotes,
            SUM(COALESCE(v.downvote_count, 0)) AS total_downvotes,
            SUM(COALESCE(v.bounty_total, 0)) AS total_bounty_amount,
            SUM(COALESCE(l.link_count, 0)) AS total_outgoing_links,
            SUM(COALESCE(h.history_event_count, 0)) AS total_history_events_on_posts
        FROM posts p
        LEFT JOIN post_votes v ON p.id = v.postid
        LEFT JOIN post_links l ON p.id = l.postid
        LEFT JOIN post_hist_by_post h ON p.id = h.post_id
        GROUP BY p.owneruserid
    ),
    user_history_metrics AS (
        SELECT
            userid AS owner_user_id,
            COUNT(*) AS history_events_performed
        FROM posthistory
        GROUP BY userid
    )
SELECT
    o.owner_user_id,
    o.total_posts,
    o.avg_post_score,
    o.avg_answer_count,
    o.avg_comment_count,
    o.total_votes,
    o.total_upvotes,
    o.total_downvotes,
    o.total_bounty_amount,
    o.total_outgoing_links,
    o.total_history_events_on_posts,
    COALESCE(u.history_events_performed, 0) AS history_events_performed_by_user
FROM owner_post_metrics o
LEFT JOIN user_history_metrics u ON o.owner_user_id = u.owner_user_id
ORDER BY o.total_posts DESC
LIMIT 20
