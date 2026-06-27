WITH post_tag_class AS (
    SELECT DISTINCT
        p.id AS post_id,
        p.container_forum_id,
        p.length,
        p.creator_person_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM post p
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
),
post_stats AS (
    SELECT
        container_forum_id AS forum_id,
        tag_class_id,
        tag_class_name,
        COUNT(*) AS post_count,
        AVG(length) AS avg_post_length,
        COUNT(DISTINCT creator_person_id) AS distinct_authors
    FROM post_tag_class
    GROUP BY container_forum_id, tag_class_id, tag_class_name
),
forum_member_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT mem.id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fhmp
        ON fhmp.forum_id = f.id
    JOIN person mem
        ON fhmp.person_id = mem.id
    GROUP BY f.id
)
SELECT
    f.title AS forum_title,
    ps.tag_class_name,
    ps.post_count,
    ps.avg_post_length,
    ps.distinct_authors,
    fm.member_count
FROM post_stats ps
JOIN forum f
    ON ps.forum_id = f.id
JOIN forum_member_counts fm
    ON ps.forum_id = fm.forum_id
ORDER BY ps.post_count DESC
LIMIT 100
