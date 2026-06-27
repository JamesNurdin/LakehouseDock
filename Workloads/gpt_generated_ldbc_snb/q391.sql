WITH
forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.moderator_person_id
    FROM forum f
),
moderator_info AS (
    SELECT
        fb.forum_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum_base fb
    JOIN person p
        ON fb.moderator_person_id = p.id
),
member_counts AS (
    SELECT
        fmp.forum_id,
        COUNT(DISTINCT fmp.person_id) AS member_count
    FROM forum_has_member_person fmp
    GROUP BY fmp.forum_id
),
tag_counts AS (
    SELECT
        ftt.forum_id,
        COUNT(DISTINCT ftt.tag_id) AS tag_count
    FROM forum_has_tag_tag ftt
    GROUP BY ftt.forum_id
),
post_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM post p
    JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_like_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count
    FROM post p
    JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count
    FROM post p
    JOIN comment c
        ON c.parent_post_id = p.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
),
members_with_interest AS (
    SELECT
        fmp.forum_id,
        COUNT(DISTINCT fmp.person_id) AS members_with_interest_count
    FROM forum_has_member_person fmp
    JOIN person p_mem
        ON fmp.person_id = p_mem.id
    JOIN person_has_interest_tag phi
        ON phi.person_id = p_mem.id
    JOIN tag t
        ON phi.tag_id = t.id
    JOIN forum_has_tag_tag ftt
        ON ftt.forum_id = fmp.forum_id
        AND ftt.tag_id = t.id
    GROUP BY fmp.forum_id
)
SELECT
    fb.forum_id,
    fb.title,
    mi.moderator_first_name,
    mi.moderator_last_name,
    mc.member_count,
    tc.tag_count,
    pm.post_count,
    pm.avg_post_length,
    cm.comment_count,
    cm.avg_comment_length,
    plc.post_like_count,
    clc.comment_like_count,
    mwi.members_with_interest_count
FROM forum_base fb
LEFT JOIN moderator_info mi
    ON fb.forum_id = mi.forum_id
LEFT JOIN member_counts mc
    ON fb.forum_id = mc.forum_id
LEFT JOIN tag_counts tc
    ON fb.forum_id = tc.forum_id
LEFT JOIN post_metrics pm
    ON fb.forum_id = pm.forum_id
LEFT JOIN comment_metrics cm
    ON fb.forum_id = cm.forum_id
LEFT JOIN post_like_counts plc
    ON fb.forum_id = plc.forum_id
LEFT JOIN comment_like_counts clc
    ON fb.forum_id = clc.forum_id
LEFT JOIN members_with_interest mwi
    ON fb.forum_id = mwi.forum_id
ORDER BY fb.forum_id
