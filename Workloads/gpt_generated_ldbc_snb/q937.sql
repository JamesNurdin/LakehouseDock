WITH comment_counts AS (
    SELECT
        tag_id,
        COUNT(*) AS comment_tag_cnt,
        COUNT(DISTINCT comment_id) AS distinct_comment_cnt
    FROM comment_has_tag_tag
    GROUP BY tag_id
),
forum_counts AS (
    SELECT
        tag_id,
        COUNT(*) AS forum_tag_cnt,
        COUNT(DISTINCT forum_id) AS distinct_forum_cnt
    FROM forum_has_tag_tag
    GROUP BY tag_id
),
post_counts AS (
    SELECT
        tag_id,
        COUNT(*) AS post_tag_cnt,
        COUNT(DISTINCT post_id) AS distinct_post_cnt
    FROM post_has_tag_tag
    GROUP BY tag_id
),
person_counts AS (
    SELECT
        tag_id,
        COUNT(*) AS person_tag_cnt,
        COUNT(DISTINCT person_id) AS distinct_person_cnt
    FROM person_has_interest_tag
    GROUP BY tag_id
),
tag_usage AS (
    SELECT
        t.id AS tag_id,
        t.type_tag_class_id AS tag_class_id,
        COALESCE(cc.comment_tag_cnt, 0) AS comment_tag_cnt,
        COALESCE(cc.distinct_comment_cnt, 0) AS distinct_comment_cnt,
        COALESCE(fc.forum_tag_cnt, 0) AS forum_tag_cnt,
        COALESCE(fc.distinct_forum_cnt, 0) AS distinct_forum_cnt,
        COALESCE(pc.post_tag_cnt, 0) AS post_tag_cnt,
        COALESCE(pc.distinct_post_cnt, 0) AS distinct_post_cnt,
        COALESCE(pic.person_tag_cnt, 0) AS person_tag_cnt,
        COALESCE(pic.distinct_person_cnt, 0) AS distinct_person_cnt
    FROM tag t
    LEFT JOIN comment_counts cc ON cc.tag_id = t.id
    LEFT JOIN forum_counts fc ON fc.tag_id = t.id
    LEFT JOIN post_counts pc ON pc.tag_id = t.id
    LEFT JOIN person_counts pic ON pic.tag_id = t.id
),
final_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        parent_tc.id AS parent_tag_class_id,
        parent_tc.name AS parent_tag_class_name,
        COUNT(DISTINCT tu.tag_id) AS distinct_tag_cnt,
        SUM(tu.comment_tag_cnt) AS total_comment_tag_assignments,
        SUM(tu.forum_tag_cnt) AS total_forum_tag_assignments,
        SUM(tu.post_tag_cnt) AS total_post_tag_assignments,
        SUM(tu.person_tag_cnt) AS total_person_tag_assignments,
        (SUM(tu.comment_tag_cnt) + SUM(tu.forum_tag_cnt) + SUM(tu.post_tag_cnt) + SUM(tu.person_tag_cnt)) AS total_tag_assignments,
        SUM(tu.distinct_comment_cnt) AS distinct_comment_cnt,
        SUM(tu.distinct_forum_cnt) AS distinct_forum_cnt,
        SUM(tu.distinct_post_cnt) AS distinct_post_cnt,
        SUM(tu.distinct_person_cnt) AS distinct_person_cnt,
        (SUM(tu.distinct_comment_cnt) + SUM(tu.distinct_forum_cnt) + SUM(tu.distinct_post_cnt) + SUM(tu.distinct_person_cnt)) AS total_distinct_entities
    FROM tag_class tc
    LEFT JOIN tag_class parent_tc ON parent_tc.id = tc.subclass_of_tag_class_id
    JOIN tag t ON t.type_tag_class_id = tc.id
    JOIN tag_usage tu ON tu.tag_id = t.id
    GROUP BY
        tc.id,
        tc.name,
        parent_tc.id,
        parent_tc.name
)
SELECT *
FROM final_agg
ORDER BY total_tag_assignments DESC
LIMIT 50
