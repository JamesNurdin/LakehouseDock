WITH tag_metrics AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count,
        COUNT(DISTINCT fht.forum_id) AS forum_count,
        COUNT(DISTINCT pit.person_id) AS person_interest_count
    FROM tag t
    LEFT JOIN post_has_tag_tag pht
        ON pht.tag_id = t.id
    LEFT JOIN post p
        ON p.id = pht.post_id
    LEFT JOIN forum_has_tag_tag fht
        ON fht.tag_id = t.id
    LEFT JOIN person_has_interest_tag pit
        ON pit.tag_id = t.id
    GROUP BY t.id, t.name
)
SELECT
    tag_id,
    tag_name,
    post_count,
    avg_post_length,
    distinct_creator_count,
    forum_count,
    person_interest_count
FROM tag_metrics
WHERE post_count > 0
ORDER BY post_count DESC
LIMIT 20
