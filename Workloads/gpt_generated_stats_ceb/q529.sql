WITH
    post_stats AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
            SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
            COALESCE(SUM(p.score), 0) AS total_post_score,
            COALESCE(AVG(p.score), 0) AS avg_post_score,
            COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts
        FROM posts p
        GROUP BY p.owneruserid
    ),
    votes_by_user AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS vote_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badge_counts AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    comments_made AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comments_made_count
        FROM comments c
        GROUP BY c.userid
    ),
    comments_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(c.id) AS comments_received_count
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    edit_counts AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS edit_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    linked_posts_raw AS (
        SELECT p.owneruserid AS user_id, pl.id AS link_id
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        UNION ALL
        SELECT p.owneruserid AS user_id, pl.id AS link_id
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
    ),
    linked_posts AS (
        SELECT user_id, COUNT(DISTINCT link_id) AS linked_posts_count
        FROM linked_posts_raw
        GROUP BY user_id
    ),
    tag_counts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.question_count, 0) AS question_count,
    COALESCE(ps.answer_count, 0) AS answer_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(ps.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(vb.vote_count, 0) AS total_votes_received,
    COALESCE(cm.comments_made_count, 0) AS comments_made,
    COALESCE(cr.comments_received_count, 0) AS comments_received,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(ec.edit_count, 0) AS edit_count,
    COALESCE(lp.linked_posts_count, 0) AS linked_posts_count,
    COALESCE(tc.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN post_stats ps ON ps.user_id = u.id
LEFT JOIN votes_by_user vb ON vb.user_id = u.id
LEFT JOIN badge_counts bc ON bc.user_id = u.id
LEFT JOIN comments_made cm ON cm.user_id = u.id
LEFT JOIN comments_received cr ON cr.user_id = u.id
LEFT JOIN edit_counts ec ON ec.user_id = u.id
LEFT JOIN linked_posts lp ON lp.user_id = u.id
LEFT JOIN tag_counts tc ON tc.user_id = u.id
ORDER BY post_count DESC
LIMIT 20
