WITH comment_counts AS (
    SELECT tag_id,
           COUNT(DISTINCT comment_id) AS comment_cnt
    FROM comment_has_tag_tag
    GROUP BY tag_id
),
forum_counts AS (
    SELECT tag_id,
           COUNT(DISTINCT forum_id) AS forum_cnt
    FROM forum_has_tag_tag
    GROUP BY tag_id
),
post_counts AS (
    SELECT tag_id,
           COUNT(DISTINCT post_id) AS post_cnt
    FROM post_has_tag_tag
    GROUP BY tag_id
),
person_counts AS (
    SELECT tag_id,
           COUNT(DISTINCT person_id) AS person_cnt
    FROM person_has_interest_tag
    GROUP BY tag_id
),
tag_usage AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        parent_tc.id AS parent_tag_class_id,
        parent_tc.name AS parent_tag_class_name,
        COALESCE(cc.comment_cnt, 0) AS comment_cnt,
        COALESCE(fc.forum_cnt, 0)   AS forum_cnt,
        COALESCE(pc.post_cnt, 0)    AS post_cnt,
        COALESCE(pic.person_cnt, 0) AS person_cnt
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class parent_tc ON tc.subclass_of_tag_class_id = parent_tc.id
    LEFT JOIN comment_counts cc ON cc.tag_id = t.id
    LEFT JOIN forum_counts   fc ON fc.tag_id = t.id
    LEFT JOIN post_counts    pc ON pc.tag_id = t.id
    LEFT JOIN person_counts  pic ON pic.tag_id = t.id
)
SELECT
    tag_class_name,
    parent_tag_class_name,
    COUNT(DISTINCT tag_id) AS distinct_tags,
    SUM(comment_cnt)       AS total_comments,
    SUM(forum_cnt)         AS total_forums,
    SUM(post_cnt)          AS total_posts,
    SUM(person_cnt)        AS total_persons,
    SUM(comment_cnt + forum_cnt + post_cnt + person_cnt) AS total_usages,
    ROUND(
        SUM(comment_cnt + forum_cnt + post_cnt + person_cnt) * 1.0 /
        NULLIF(COUNT(DISTINCT tag_id), 0),
        2
    ) AS avg_usages_per_tag
FROM tag_usage
GROUP BY tag_class_name, parent_tag_class_name
ORDER BY total_posts DESC
LIMIT 20
