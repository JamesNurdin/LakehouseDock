WITH tag_class_tags AS (
    SELECT
        tc.id AS tag_class_id,
        t.id AS tag_id
    FROM tag_class tc
    JOIN tag t
        ON t.type_tag_class_id = tc.id
),

post_tagged AS (
    SELECT DISTINCT
        tc_t.tag_class_id,
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id AS creator_person_id
    FROM tag_class_tags tc_t
    JOIN post_has_tag_tag pht
        ON pht.tag_id = tc_t.tag_id
    JOIN post p
        ON p.id = pht.post_id
),

comment_tagged AS (
    SELECT DISTINCT
        tc_t.tag_class_id,
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS creator_person_id
    FROM tag_class_tags tc_t
    JOIN comment_has_tag_tag cht
        ON cht.tag_id = tc_t.tag_id
    JOIN comment c
        ON c.id = cht.comment_id
),

forum_tagged AS (
    SELECT DISTINCT
        tc_t.tag_class_id,
        f.id AS forum_id,
        f.moderator_person_id AS moderator_person_id
    FROM tag_class_tags tc_t
    JOIN forum_has_tag_tag fht
        ON fht.tag_id = tc_t.tag_id
    JOIN forum f
        ON f.id = fht.forum_id
),

post_metrics AS (
    SELECT
        pt.tag_class_id,
        COUNT(DISTINCT pt.post_id) AS post_count,
        SUM(pt.post_length) / NULLIF(COUNT(DISTINCT pt.post_id), 0) AS avg_post_length,
        COUNT(DISTINCT pt.creator_person_id) AS post_creator_cnt
    FROM post_tagged pt
    GROUP BY pt.tag_class_id
),

comment_metrics AS (
    SELECT
        ct.tag_class_id,
        COUNT(DISTINCT ct.comment_id) AS comment_count,
        SUM(ct.comment_length) / NULLIF(COUNT(DISTINCT ct.comment_id), 0) AS avg_comment_length,
        COUNT(DISTINCT ct.creator_person_id) AS comment_creator_cnt
    FROM comment_tagged ct
    GROUP BY ct.tag_class_id
),

forum_metrics AS (
    SELECT
        ft.tag_class_id,
        COUNT(DISTINCT ft.forum_id) AS forum_count,
        COUNT(DISTINCT ft.moderator_person_id) AS forum_moderator_cnt
    FROM forum_tagged ft
    GROUP BY ft.tag_class_id
),

creator_union AS (
    SELECT pt.tag_class_id, pt.creator_person_id AS creator_id FROM post_tagged pt
    UNION
    SELECT ct.tag_class_id, ct.creator_person_id FROM comment_tagged ct
    UNION
    SELECT ft.tag_class_id, ft.moderator_person_id FROM forum_tagged ft
),

creator_metrics AS (
    SELECT
        cu.tag_class_id,
        COUNT(DISTINCT cu.creator_id) AS distinct_creator_count
    FROM creator_union cu
    GROUP BY cu.tag_class_id
),

interest_metrics AS (
    SELECT
        tc_t.tag_class_id,
        COUNT(DISTINCT pit.person_id) AS interest_person_count
    FROM tag_class_tags tc_t
    JOIN person_has_interest_tag pit
        ON pit.tag_id = tc_t.tag_id
    GROUP BY tc_t.tag_class_id
)

SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fm.forum_count, 0) AS forum_count,
    COALESCE(pm.post_creator_cnt, 0) + COALESCE(cm.comment_creator_cnt, 0) + COALESCE(fm.forum_moderator_cnt, 0) AS total_creator_events,
    COALESCE(crm.distinct_creator_count, 0) AS distinct_creator_count,
    COALESCE(im.interest_person_count, 0) AS interest_person_count
FROM tag_class tc
LEFT JOIN post_metrics pm
    ON pm.tag_class_id = tc.id
LEFT JOIN comment_metrics cm
    ON cm.tag_class_id = tc.id
LEFT JOIN forum_metrics fm
    ON fm.tag_class_id = tc.id
LEFT JOIN creator_metrics crm
    ON crm.tag_class_id = tc.id
LEFT JOIN interest_metrics im
    ON im.tag_class_id = tc.id
ORDER BY post_count DESC
LIMIT 10
