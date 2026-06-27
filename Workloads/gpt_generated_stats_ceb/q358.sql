WITH
    post_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(p.score) AS total_score,
            AVG(p.score) AS avg_score,
            SUM(p.answercount) AS total_answers,
            SUM(p.commentcount) AS total_comments,
            SUM(p.favoritecount) AS total_favorites
        FROM posts p
        GROUP BY p.owneruserid
    ),
    votes_received_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS votes_received,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_cast_agg AS (
        SELECT
            v.userid AS user_id,
            COUNT(v.id) AS votes_cast,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_cast
        FROM votes v
        GROUP BY v.userid
    ),
    badges_agg AS (
        SELECT
            b.userid AS user_id,
            COUNT(b.id) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    tags_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tags_used
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_agg AS (
        SELECT
            ph.userid AS user_id,
            COUNT(ph.id) AS post_edits,
            COUNT(DISTINCT ph.postid) AS distinct_posts_edited
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    comments_on_posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(c.id) AS comments_on_posts
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    comments_by_user_agg AS (
        SELECT
            c.userid AS user_id,
            COUNT(c.id) AS comments_made
        FROM comments c
        GROUP BY c.userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(pa.total_posts, 0) AS total_posts,
    COALESCE(pa.total_score, 0) AS total_score,
    COALESCE(pa.avg_score, 0) AS avg_score,
    COALESCE(pa.total_answers, 0) AS total_answers,
    COALESCE(pa.total_comments, 0) AS total_comments,
    COALESCE(pa.total_favorites, 0) AS total_favorites,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(t.distinct_tags_used, 0) AS distinct_tags_used,
    COALESCE(ph.post_edits, 0) AS post_edits,
    COALESCE(ph.distinct_posts_edited, 0) AS distinct_posts_edited,
    COALESCE(cp.comments_on_posts, 0) AS comments_on_posts,
    COALESCE(cu.comments_made, 0) AS comments_made
FROM users u
LEFT JOIN post_agg pa ON u.id = pa.user_id
LEFT JOIN votes_received_agg vr ON u.id = vr.user_id
LEFT JOIN votes_cast_agg vc ON u.id = vc.user_id
LEFT JOIN badges_agg b ON u.id = b.user_id
LEFT JOIN tags_agg t ON u.id = t.user_id
LEFT JOIN posthistory_agg ph ON u.id = ph.user_id
LEFT JOIN comments_on_posts_agg cp ON u.id = cp.user_id
LEFT JOIN comments_by_user_agg cu ON u.id = cu.user_id
ORDER BY u.reputation DESC
LIMIT 100
