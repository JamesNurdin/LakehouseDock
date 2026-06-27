WITH comment_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN tag t
        ON t.id = cht.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    GROUP BY tc.id, tc.name
),
post_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators
    FROM post p
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON t.id = pht.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    GROUP BY tc.id, tc.name
),
interest_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT pi.person_id) AS distinct_interested_persons
    FROM person_has_interest_tag pi
    JOIN tag t
        ON t.id = pi.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    GROUP BY tc.id, tc.name
)
SELECT
    COALESCE(ca.tag_class_name, pa.tag_class_name, ia.tag_class_name) AS tag_class_name,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ca.distinct_comment_creators, 0) AS distinct_comment_creators,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.avg_post_length, 0) AS avg_post_length,
    COALESCE(pa.distinct_post_creators, 0) AS distinct_post_creators,
    COALESCE(ia.distinct_interested_persons, 0) AS distinct_interested_persons,
    (COALESCE(ca.comment_count, 0) + COALESCE(pa.post_count, 0)) AS total_activities
FROM comment_agg ca
FULL OUTER JOIN post_agg pa
    ON pa.tag_class_id = ca.tag_class_id
FULL OUTER JOIN interest_agg ia
    ON ia.tag_class_id = COALESCE(ca.tag_class_id, pa.tag_class_id)
ORDER BY total_activities DESC
LIMIT 20
