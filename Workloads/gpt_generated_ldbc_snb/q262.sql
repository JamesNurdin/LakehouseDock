WITH tags AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        parent_tc.id AS parent_tag_class_id,
        parent_tc.name AS parent_tag_class_name
    FROM tag t
    JOIN tag_class tc
      ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class parent_tc
      ON tc.subclass_of_tag_class_id = parent_tc.id
),
comment_counts AS (
    SELECT
        tg.tag_class_id,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt,
        COUNT(DISTINCT cht.tag_id) AS distinct_tag_cnt_comment
    FROM comment_has_tag_tag cht
    JOIN tags tg
      ON cht.tag_id = tg.tag_id
    GROUP BY tg.tag_class_id
),
forum_counts AS (
    SELECT
        tg.tag_class_id,
        COUNT(DISTINCT fht.forum_id) AS forum_cnt,
        COUNT(DISTINCT fht.tag_id) AS distinct_tag_cnt_forum
    FROM forum_has_tag_tag fht
    JOIN tags tg
      ON fht.tag_id = tg.tag_id
    GROUP BY tg.tag_class_id
),
post_counts AS (
    SELECT
        tg.tag_class_id,
        COUNT(DISTINCT pht.post_id) AS post_cnt,
        COUNT(DISTINCT pht.tag_id) AS distinct_tag_cnt_post
    FROM post_has_tag_tag pht
    JOIN tags tg
      ON pht.tag_id = tg.tag_id
    GROUP BY tg.tag_class_id
),
person_counts AS (
    SELECT
        tg.tag_class_id,
        COUNT(DISTINCT pit.person_id) AS person_cnt,
        COUNT(DISTINCT pit.tag_id) AS distinct_tag_cnt_person
    FROM person_has_interest_tag pit
    JOIN tags tg
      ON pit.tag_id = tg.tag_id
    GROUP BY tg.tag_class_id
)
SELECT
    COALESCE(parent_tc.name, tc.name) AS top_tag_class,
    tc.name AS tag_class,
    COALESCE(cc.comment_cnt, 0) AS comment_cnt,
    COALESCE(fc.forum_cnt, 0) AS forum_cnt,
    COALESCE(pc.post_cnt, 0) AS post_cnt,
    COALESCE(pc2.person_cnt, 0) AS person_cnt,
    COALESCE(cc.distinct_tag_cnt_comment, 0)
      + COALESCE(fc.distinct_tag_cnt_forum, 0)
      + COALESCE(pc.distinct_tag_cnt_post, 0)
      + COALESCE(pc2.distinct_tag_cnt_person, 0) AS total_distinct_tags_used
FROM tag_class tc
LEFT JOIN tag_class parent_tc
  ON tc.subclass_of_tag_class_id = parent_tc.id
LEFT JOIN comment_counts cc
  ON cc.tag_class_id = tc.id
LEFT JOIN forum_counts fc
  ON fc.tag_class_id = tc.id
LEFT JOIN post_counts pc
  ON pc.tag_class_id = tc.id
LEFT JOIN person_counts pc2
  ON pc2.tag_class_id = tc.id
ORDER BY top_tag_class, tag_class
