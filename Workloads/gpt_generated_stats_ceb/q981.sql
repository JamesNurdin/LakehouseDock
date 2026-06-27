WITH
    owned_posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS owned_posts_count,
            SUM(p.score) AS owned_posts_score_sum,
            AVG(p.score) AS owned_posts_score_avg
        FROM posts p
        GROUP BY p.owneruserid
    ),
    edited_posts_agg AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS edited_posts_count,
            SUM(p.score) AS edited_posts_score_sum,
            AVG(p.score) AS edited_posts_score_avg
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    comments_written_agg AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comments_written_count,
            SUM(c.score) AS comments_written_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    comments_on_owned_posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(c.id) AS comments_on_owned_posts_count,
            COALESCE(SUM(c.score), 0) AS comments_on_owned_posts_score_sum
        FROM posts p
        LEFT JOIN comments c ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    links_on_owned_posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS links_on_owned_posts_count
        FROM posts p
        LEFT JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    related_links_on_owned_posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS related_links_on_owned_posts_count
        FROM posts p
        LEFT JOIN postlinks pl ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    tags_on_owned_posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(t.id) AS tags_on_owned_posts_count
        FROM posts p
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(op.owned_posts_count, 0) AS owned_posts_count,
    COALESCE(op.owned_posts_score_sum, 0) AS owned_posts_score_sum,
    COALESCE(op.owned_posts_score_avg, 0) AS owned_posts_score_avg,
    COALESCE(ep.edited_posts_count, 0) AS edited_posts_count,
    COALESCE(ep.edited_posts_score_sum, 0) AS edited_posts_score_sum,
    COALESCE(ep.edited_posts_score_avg, 0) AS edited_posts_score_avg,
    COALESCE(cw.comments_written_count, 0) AS comments_written_count,
    COALESCE(cw.comments_written_score_sum, 0) AS comments_written_score_sum,
    COALESCE(cop.comments_on_owned_posts_count, 0) AS comments_on_owned_posts_count,
    COALESCE(cop.comments_on_owned_posts_score_sum, 0) AS comments_on_owned_posts_score_sum,
    COALESCE(lop.links_on_owned_posts_count, 0) AS links_on_owned_posts_count,
    COALESCE(rlop.related_links_on_owned_posts_count, 0) AS related_links_on_owned_posts_count,
    COALESCE(tok.tags_on_owned_posts_count, 0) AS tags_on_owned_posts_count
FROM users u
LEFT JOIN owned_posts_agg op ON op.user_id = u.id
LEFT JOIN edited_posts_agg ep ON ep.user_id = u.id
LEFT JOIN comments_written_agg cw ON cw.user_id = u.id
LEFT JOIN comments_on_owned_posts_agg cop ON cop.user_id = u.id
LEFT JOIN links_on_owned_posts_agg lop ON lop.user_id = u.id
LEFT JOIN related_links_on_owned_posts_agg rlop ON rlop.user_id = u.id
LEFT JOIN tags_on_owned_posts_agg tok ON tok.user_id = u.id
ORDER BY owned_posts_score_sum DESC
LIMIT 100
