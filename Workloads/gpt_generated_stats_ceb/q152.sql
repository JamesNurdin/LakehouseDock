WITH user_post_agg AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        CASE WHEN COUNT(p.id) = 0 THEN 0 ELSE AVG(p.score) END AS avg_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_post_views,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorites,
        COALESCE(SUM(p.answercount), 0) AS total_answers,
        COALESCE(SUM(p.commentcount), 0) AS total_comments
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation, u.creationdate, u.views, u.upvotes, u.downvotes
),
user_post_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_on_posts_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY u.id
),
user_post_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_on_posts_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_post_history AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS post_history_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
user_post_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_outgoing_links AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS outgoing_links
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
),
user_incoming_links AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS incoming_links
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.relatedpostid = p.id
    GROUP BY u.id
)
SELECT
    upa.user_id,
    upa.reputation,
    upa.creationdate,
    upa.views,
    upa.upvotes,
    upa.downvotes,
    upa.post_count,
    upa.total_post_score,
    upa.avg_post_score,
    upa.total_post_views,
    upa.total_favorites,
    upa.total_answers,
    upa.total_comments,
    upc.comment_on_posts_count,
    upv.vote_on_posts_count,
    ub.badge_count,
    uph.post_history_count,
    upt.tag_count,
    uol.outgoing_links,
    uil.incoming_links
FROM user_post_agg upa
LEFT JOIN user_post_comments upc
    ON upc.user_id = upa.user_id
LEFT JOIN user_post_votes upv
    ON upv.user_id = upa.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = upa.user_id
LEFT JOIN user_post_history uph
    ON uph.user_id = upa.user_id
LEFT JOIN user_post_tags upt
    ON upt.user_id = upa.user_id
LEFT JOIN user_outgoing_links uol
    ON uol.user_id = upa.user_id
LEFT JOIN user_incoming_links uil
    ON uil.user_id = upa.user_id
ORDER BY upa.post_count DESC
LIMIT 100
