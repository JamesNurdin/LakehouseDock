WITH
    forum_base AS (
        SELECT
            f.id AS forum_id,
            f.title AS forum_title,
            p_mod.first_name AS moderator_first_name,
            p_mod.last_name AS moderator_last_name
        FROM forum f
        LEFT JOIN person p_mod
            ON f.moderator_person_id = p_mod.id
    ),
    post_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(po.id) AS post_count,
            AVG(po.length) AS avg_post_length
        FROM post po
        JOIN forum f
            ON po.container_forum_id = f.id
        GROUP BY f.id
    ),
    post_like_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(pl.person_id) AS post_like_count
        FROM post po
        LEFT JOIN person_likes_post pl
            ON pl.post_id = po.id
        JOIN forum f
            ON po.container_forum_id = f.id
        GROUP BY f.id
    ),
    comment_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(co.id) AS comment_count,
            AVG(co.length) AS avg_comment_length
        FROM comment co
        JOIN post po
            ON co.parent_post_id = po.id
        JOIN forum f
            ON po.container_forum_id = f.id
        GROUP BY f.id
    ),
    comment_like_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(cl.person_id) AS comment_like_count
        FROM comment co
        JOIN post po
            ON co.parent_post_id = po.id
        JOIN forum f
            ON po.container_forum_id = f.id
        LEFT JOIN person_likes_comment cl
            ON cl.comment_id = co.id
        GROUP BY f.id
    ),
    comment_tag_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT cht.tag_id) AS distinct_comment_tag_count
        FROM comment co
        JOIN post po
            ON co.parent_post_id = po.id
        JOIN forum f
            ON po.container_forum_id = f.id
        LEFT JOIN comment_has_tag_tag cht
            ON cht.comment_id = co.id
        GROUP BY f.id
    ),
    member_agg AS (
        SELECT
            forum_id,
            COUNT(DISTINCT person_id) AS member_count
        FROM forum_has_member_person
        GROUP BY forum_id
    )
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.avg_post_length, 0) AS avg_post_length,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ma.member_count, 0) AS member_count,
    COALESCE(cta.distinct_comment_tag_count, 0) AS distinct_comment_tag_count,
    COALESCE(pla.post_like_count, 0) AS post_like_count,
    COALESCE(cla.comment_like_count, 0) AS comment_like_count
FROM forum_base fb
LEFT JOIN post_agg pa
    ON fb.forum_id = pa.forum_id
LEFT JOIN post_like_agg pla
    ON fb.forum_id = pla.forum_id
LEFT JOIN comment_agg ca
    ON fb.forum_id = ca.forum_id
LEFT JOIN comment_like_agg cla
    ON fb.forum_id = cla.forum_id
LEFT JOIN comment_tag_agg cta
    ON fb.forum_id = cta.forum_id
LEFT JOIN member_agg ma
    ON fb.forum_id = ma.forum_id
ORDER BY post_count DESC
LIMIT 50
