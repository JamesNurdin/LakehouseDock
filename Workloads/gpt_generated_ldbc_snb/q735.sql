WITH
    post_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(p.id) AS post_count,
            SUM(p.length) AS total_post_length,
            AVG(p.length) AS avg_post_length
        FROM post p
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    comment_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(c.id) AS comment_count,
            SUM(c.length) AS total_comment_length,
            AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    post_likes_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(plp.person_id) AS post_like_count
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    comment_likes_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(plc.person_id) AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    participants AS (
        SELECT
            f.id AS forum_id,
            p.creator_person_id AS participant_id
        FROM post p
        JOIN forum f ON p.container_forum_id = f.id
        UNION
        SELECT
            f.id AS forum_id,
            c.creator_person_id AS participant_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
    ),
    participant_agg AS (
        SELECT
            forum_id,
            COUNT(DISTINCT participant_id) AS participant_count
        FROM participants
        GROUP BY forum_id
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.avg_post_length, 0) AS avg_post_length,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    COALESCE(pag.participant_count, 0) AS participant_count,
    (COALESCE(pl.post_like_count, 0) + COALESCE(cl.comment_like_count, 0)) AS total_like_count,
    (COALESCE(pa.post_count, 0) + COALESCE(ca.comment_count, 0)) AS total_content_count,
    CASE
        WHEN (COALESCE(pa.post_count, 0) + COALESCE(ca.comment_count, 0)) = 0 THEN 0
        ELSE (COALESCE(pl.post_like_count, 0) + COALESCE(cl.comment_like_count, 0)) * 1.0 / (COALESCE(pa.post_count, 0) + COALESCE(ca.comment_count, 0))
    END AS likes_per_content
FROM forum f
LEFT JOIN person mod ON f.moderator_person_id = mod.id
LEFT JOIN post_agg pa ON f.id = pa.forum_id
LEFT JOIN comment_agg ca ON f.id = ca.forum_id
LEFT JOIN post_likes_agg pl ON f.id = pl.forum_id
LEFT JOIN comment_likes_agg cl ON f.id = cl.forum_id
LEFT JOIN participant_agg pag ON f.id = pag.forum_id
ORDER BY f.id
