WITH forum_tag_class_stats AS (
    SELECT
        f.id AS forum_id,
        f.title,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT t.id) AS tag_count,
        COUNT(DISTINCT CASE WHEN pht.person_id IS NOT NULL THEN t.id END) AS overlap_tag_count
    FROM forum f
    JOIN forum_has_tag_tag fht
        ON f.id = fht.forum_id
    JOIN tag t
        ON fht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN person_has_interest_tag pht
        ON pht.tag_id = t.id
        AND pht.person_id = f.moderator_person_id
    GROUP BY f.id, f.title, tc.id, tc.name
),
forum_top_tag_class AS (
    SELECT
        forum_id,
        title,
        tag_class_name,
        tag_count,
        overlap_tag_count,
        RANK() OVER (PARTITION BY forum_id ORDER BY tag_count DESC) AS class_rank
    FROM forum_tag_class_stats
)
SELECT
    forum_id,
    title,
    tag_class_name,
    tag_count,
    overlap_tag_count
FROM forum_top_tag_class
WHERE class_rank = 1
ORDER BY tag_count DESC
