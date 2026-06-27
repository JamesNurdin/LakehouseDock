WITH tag_counts_per_forum AS (
    SELECT
        forum_id,
        COUNT(*) AS tag_count
    FROM ldbc_snb_bi_sf0003.forum_has_tag_tag
    GROUP BY forum_id
)
SELECT
    t.name AS tag_name,
    COUNT(DISTINCT f.id) AS distinct_forum_count,
    COUNT(DISTINCT f.moderator_person_id) AS distinct_moderator_count,
    AVG(tag_counts_per_forum.tag_count) AS avg_tags_per_forum
FROM ldbc_snb_bi_sf0003.forum AS f
JOIN ldbc_snb_bi_sf0003.forum_has_tag_tag AS ft
    ON ft.forum_id = f.id
JOIN ldbc_snb_bi_sf0003.tag AS t
    ON ft.tag_id = t.id
JOIN tag_counts_per_forum
    ON tag_counts_per_forum.forum_id = f.id
GROUP BY t.name
ORDER BY distinct_forum_count DESC
LIMIT 10
