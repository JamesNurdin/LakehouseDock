WITH
    posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.answercount) AS avg_answer_count,
            SUM(p.favoritecount) AS total_favorite_count
        FROM posts p
        GROUP BY p.owneruserid
    ),
    comments_agg AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(c.score) AS total_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    votes_given_agg AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS vote_given_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_given_count,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_given_count
        FROM votes v
        GROUP BY v.userid
    ),
    votes_received_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS vote_received_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received_count,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received_count
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_agg AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    posthistory_agg AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    edits_agg AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS edit_count
        FROM posts p
        WHERE p.lasteditoruserid IS NOT NULL
        GROUP BY p.lasteditoruserid
    ),
    postlinks_out_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS outgoing_link_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_in_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS incoming_link_count
        FROM posts p
        JOIN postlinks pl ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    tags_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(t.id) AS tag_excerpt_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.total_post_score, 0) AS total_post_score,
    COALESCE(pa.avg_answer_count, 0) AS avg_answer_count,
    COALESCE(pa.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.total_comment_score, 0) AS total_comment_score,
    COALESCE(ba.badge_count, 0) AS badge_count,
    COALESCE(pha.posthistory_count, 0) AS posthistory_count,
    COALESCE(ea.edit_count, 0) AS edit_count,
    COALESCE(vga.vote_given_count, 0) AS vote_given_count,
    COALESCE(vga.upvote_given_count, 0) AS upvote_given_count,
    COALESCE(vga.downvote_given_count, 0) AS downvote_given_count,
    COALESCE(vra.vote_received_count, 0) AS vote_received_count,
    COALESCE(vra.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(vra.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(pl_out.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(pl_in.incoming_link_count, 0) AS incoming_link_count,
    COALESCE(tg.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN posts_agg pa ON pa.user_id = u.id
LEFT JOIN comments_agg ca ON ca.user_id = u.id
LEFT JOIN badges_agg ba ON ba.user_id = u.id
LEFT JOIN posthistory_agg pha ON pha.user_id = u.id
LEFT JOIN edits_agg ea ON ea.user_id = u.id
LEFT JOIN votes_given_agg vga ON vga.user_id = u.id
LEFT JOIN votes_received_agg vra ON vra.user_id = u.id
LEFT JOIN postlinks_out_agg pl_out ON pl_out.user_id = u.id
LEFT JOIN postlinks_in_agg pl_in ON pl_in.user_id = u.id
LEFT JOIN tags_agg tg ON tg.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
