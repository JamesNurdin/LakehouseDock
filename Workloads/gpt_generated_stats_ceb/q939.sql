WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.viewcount) AS total_viewcount,
            SUM(p.favoritecount) AS total_favoritecount,
            SUM(p.answercount) AS total_answercount,
            SUM(p.commentcount) AS total_commentcount
        FROM posts p
        GROUP BY p.owneruserid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_count,
            SUM(v.bountyamount) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast_count
        FROM votes v
        GROUP BY v.userid
    ),
    comments_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS comments_received_count
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    comments_written AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comments_written_count
        FROM comments c
        GROUP BY c.userid
    ),
    badge_counts AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    tag_excerpts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_excerpt_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(cr.comments_received_count, 0) AS comments_received_count,
    COALESCE(cw.comments_written_count, 0) AS comments_written_count,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(te.tag_excerpt_count, 0) AS tag_excerpt_count,
    RANK() OVER (ORDER BY COALESCE(up.total_post_score, 0) DESC) AS post_score_rank
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN votes_cast vc ON vc.user_id = u.id
LEFT JOIN comments_received cr ON cr.user_id = u.id
LEFT JOIN comments_written cw ON cw.user_id = u.id
LEFT JOIN badge_counts bc ON bc.user_id = u.id
LEFT JOIN tag_excerpts te ON te.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
