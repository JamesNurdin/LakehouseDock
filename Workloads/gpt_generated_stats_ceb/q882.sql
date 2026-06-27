WITH
    user_badges AS (
        SELECT userid AS user_id, COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_comments AS (
        SELECT userid AS user_id, COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT userid AS user_id, COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    user_posts AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS post_count,
               AVG(score) AS avg_post_score,
               SUM(score) AS total_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS user_id, COUNT(v.id) AS votes_received_count
        FROM posts p
        JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT userid AS user_id, COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY userid
    ),
    user_tag_excerpts AS (
        SELECT p.owneruserid AS user_id, COUNT(t.id) AS tag_excerpt_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_outgoing_links AS (
        SELECT p.owneruserid AS user_id, COUNT(pl.id) AS outgoing_link_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_incoming_links AS (
        SELECT p.owneruserid AS user_id, COUNT(pl.id) AS incoming_link_count
        FROM posts p
        JOIN postlinks pl ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(t.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(ol.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(il.incoming_link_count, 0) AS incoming_link_count,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    (u.reputation * 0.001
     + COALESCE(b.badge_count, 0) * 10
     + COALESCE(p.post_count, 0) * 5
     + COALESCE(c.comment_count, 0) * 2
     + COALESCE(vc.votes_cast_count, 0) * 1
     + COALESCE(vr.votes_received_count, 0) * 1
     + COALESCE(e.edit_count, 0) * 3
     + COALESCE(t.tag_excerpt_count, 0) * 4
     + COALESCE(ol.outgoing_link_count, 0) * 2
     + COALESCE(il.incoming_link_count, 0) * 2) AS activity_score
FROM users u
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_edits e ON e.user_id = u.id
LEFT JOIN user_tag_excerpts t ON t.user_id = u.id
LEFT JOIN user_outgoing_links ol ON ol.user_id = u.id
LEFT JOIN user_incoming_links il ON il.user_id = u.id
ORDER BY activity_score DESC
LIMIT 10
