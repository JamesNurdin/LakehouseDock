WITH tag_class_stats AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT t.id) AS tag_cnt,
        COUNT(DISTINCT pht.post_id) AS post_cnt,
        COUNT(pht.tag_id) AS post_tag_assignments,
        COUNT(DISTINCT p.id) AS person_interest_cnt,
        COUNT(phi.tag_id) AS interest_tag_assignments,
        COUNT(DISTINCT f.id) AS forum_cnt,
        CASE WHEN COUNT(DISTINCT pht.post_id) > 0
            THEN CAST(COUNT(pht.tag_id) AS double) / COUNT(DISTINCT pht.post_id)
            ELSE NULL
        END AS avg_tags_per_post,
        CASE WHEN COUNT(DISTINCT p.id) > 0
            THEN CAST(COUNT(phi.tag_id) AS double) / COUNT(DISTINCT p.id)
            ELSE NULL
        END AS avg_interest_tags_per_person
    FROM tag_class tc
    JOIN tag t ON t.type_tag_class_id = tc.id
    LEFT JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    LEFT JOIN person_has_interest_tag phi ON phi.tag_id = t.id
    LEFT JOIN person p ON p.id = phi.person_id
    LEFT JOIN forum_has_tag_tag fht ON fht.tag_id = t.id
    LEFT JOIN forum f ON f.id = fht.forum_id
    GROUP BY tc.id, tc.name
)
SELECT *
FROM tag_class_stats
ORDER BY post_cnt DESC
LIMIT 10
