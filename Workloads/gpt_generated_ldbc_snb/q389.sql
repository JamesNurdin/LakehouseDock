WITH
members_agg AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
interest_tags_agg AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT pit.tag_id) AS interest_tag_count
    FROM forum_has_member_person fm
    JOIN person_has_interest_tag pit
        ON pit.person_id = fm.person_id
    GROUP BY fm.forum_id
),
knows_agg AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT pk.person2_id) AS knows_count
    FROM forum_has_member_person fm
    JOIN person_knows_person pk
        ON pk.person1_id = fm.person_id
    GROUP BY fm.forum_id
),
post_metrics AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM post po
    GROUP BY po.container_forum_id
),
post_likes_agg AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(DISTINCT plp.person_id) AS post_likes_count
    FROM post po
    LEFT JOIN person_likes_post plp
        ON plp.post_id = po.id
    GROUP BY po.container_forum_id
),
comment_metrics AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post po
        ON c.parent_post_id = po.id
    GROUP BY po.container_forum_id
),
comment_tags_agg AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(DISTINCT cht.tag_id) AS comment_tag_count
    FROM comment c
    JOIN post po
        ON c.parent_post_id = po.id
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    GROUP BY po.container_forum_id
),
comment_likes_agg AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(DISTINCT plc.person_id) AS comment_likes_count
    FROM comment c
    JOIN post po
        ON c.parent_post_id = po.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY po.container_forum_id
),
moderator_info AS (
    SELECT
        f.id AS forum_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p
        ON f.moderator_person_id = p.id
)

SELECT
    f.id AS forum_id,
    f.title,
    mi.moderator_first_name,
    mi.moderator_last_name,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(it.interest_tag_count, 0) AS interest_tag_count,
    COALESCE(k.knows_count, 0) AS knows_count,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(pl.post_likes_count, 0) AS post_likes_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ct.comment_tag_count, 0) AS comment_tag_count,
    COALESCE(cl.comment_likes_count, 0) AS comment_likes_count
FROM forum f
LEFT JOIN moderator_info mi
    ON f.id = mi.forum_id
LEFT JOIN members_agg m
    ON f.id = m.forum_id
LEFT JOIN interest_tags_agg it
    ON f.id = it.forum_id
LEFT JOIN knows_agg k
    ON f.id = k.forum_id
LEFT JOIN post_metrics pm
    ON f.id = pm.forum_id
LEFT JOIN post_likes_agg pl
    ON f.id = pl.forum_id
LEFT JOIN comment_metrics cm
    ON f.id = cm.forum_id
LEFT JOIN comment_tags_agg ct
    ON f.id = ct.forum_id
LEFT JOIN comment_likes_agg cl
    ON f.id = cl.forum_id
ORDER BY f.id
