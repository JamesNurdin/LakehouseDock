WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person p_mod
        ON f.moderator_person_id = p_mod.id
),
forum_members AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fmp
        ON f.id = fmp.forum_id
    JOIN person p
        ON fmp.person_id = p.id
    GROUP BY f.id
),
forum_tags AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM forum f
    JOIN forum_has_tag_tag fht
        ON f.id = fht.forum_id
    JOIN tag t
        ON fht.tag_id = t.id
    GROUP BY f.id
),
forum_posts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM forum f
    JOIN post po
        ON po.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT co.id) AS comment_count,
        AVG(co.length) AS avg_comment_length,
        COUNT(DISTINCT pl.id) AS comment_country_count
    FROM forum f
    JOIN post po
        ON po.container_forum_id = f.id
    JOIN comment co
        ON co.parent_post_id = po.id
    LEFT JOIN place pl
        ON co.location_country_id = pl.id
    GROUP BY f.id
),
forum_knows AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT CONCAT(CAST(p1.id AS varchar), '-', CAST(p2.id AS varchar))) AS member_knows_relationships
    FROM forum f
    JOIN forum_has_member_person fmp1
        ON f.id = fmp1.forum_id
    JOIN person p1
        ON fmp1.person_id = p1.id
    JOIN person_knows_person pk
        ON pk.person1_id = p1.id
    JOIN person p2
        ON pk.person2_id = p2.id
    JOIN forum_has_member_person fmp2
        ON f.id = fmp2.forum_id
        AND fmp2.person_id = p2.id
    GROUP BY f.id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(ft.tag_count, 0) AS tag_count,
    COALESCE(fp.post_count, 0) AS post_count,
    fp.avg_post_length,
    COALESCE(fc.comment_count, 0) AS comment_count,
    fc.avg_comment_length,
    COALESCE(fc.comment_country_count, 0) AS comment_country_count,
    COALESCE(fk.member_knows_relationships, 0) AS member_knows_relationships
FROM forum_base fb
LEFT JOIN forum_members fm
    ON fb.forum_id = fm.forum_id
LEFT JOIN forum_tags ft
    ON fb.forum_id = ft.forum_id
LEFT JOIN forum_posts fp
    ON fb.forum_id = fp.forum_id
LEFT JOIN forum_comments fc
    ON fb.forum_id = fc.forum_id
LEFT JOIN forum_knows fk
    ON fb.forum_id = fk.forum_id
ORDER BY member_count DESC
LIMIT 10
