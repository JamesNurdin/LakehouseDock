WITH forum_info AS (
    SELECT id AS forum_id,
           title AS forum_title
    FROM forum
),
forum_posts AS (
    SELECT p.id AS post_id,
           p.container_forum_id AS forum_id
    FROM post p
    JOIN forum f ON p.container_forum_id = f.id
),
post_tags AS (
    SELECT fp.forum_id,
           pht.tag_id,
           t.name AS tag_name
    FROM forum_posts fp
    JOIN post_has_tag_tag pht ON pht.post_id = fp.post_id
    JOIN tag t ON t.id = pht.tag_id
),
post_tag_counts AS (
    SELECT forum_id,
           tag_id,
           tag_name,
           count(*) AS tag_use_cnt
    FROM post_tags
    GROUP BY forum_id, tag_id, tag_name
),
top_tag AS (
    SELECT forum_id,
           tag_id,
           tag_name,
           tag_use_cnt,
           row_number() OVER (PARTITION BY forum_id ORDER BY tag_use_cnt DESC) AS rn
    FROM post_tag_counts
),
forum_post_counts AS (
    SELECT forum_id,
           count(distinct post_id) AS post_cnt
    FROM forum_posts
    GROUP BY forum_id
),
forum_member_counts AS (
    SELECT fm.forum_id,
           count(distinct fm.person_id) AS member_cnt
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_member_interest_tags AS (
    SELECT fm.forum_id,
           pit.tag_id
    FROM forum_has_member_person fm
    JOIN person p ON p.id = fm.person_id
    JOIN person_has_interest_tag pit ON pit.person_id = p.id
),
forum_interest_tag_counts AS (
    SELECT forum_id,
           count(distinct tag_id) AS distinct_member_interest_tag_cnt
    FROM forum_member_interest_tags
    GROUP BY forum_id
),
forum_distinct_post_tag_counts AS (
    SELECT forum_id,
           count(distinct tag_id) AS distinct_post_tag_cnt
    FROM post_tags
    GROUP BY forum_id
)
SELECT fi.forum_id,
       fi.forum_title,
       fpc.post_cnt,
       fmc.member_cnt,
       fdptc.distinct_post_tag_cnt,
       fitc.distinct_member_interest_tag_cnt,
       tt.tag_name AS top_tag_name,
       tt.tag_use_cnt AS top_tag_usage
FROM forum_info fi
LEFT JOIN forum_post_counts fpc ON fpc.forum_id = fi.forum_id
LEFT JOIN forum_member_counts fmc ON fmc.forum_id = fi.forum_id
LEFT JOIN forum_distinct_post_tag_counts fdptc ON fdptc.forum_id = fi.forum_id
LEFT JOIN forum_interest_tag_counts fitc ON fitc.forum_id = fi.forum_id
LEFT JOIN (
    SELECT forum_id,
           tag_name,
           tag_use_cnt
    FROM top_tag
    WHERE rn = 1
) tt ON tt.forum_id = fi.forum_id
ORDER BY fpc.post_cnt DESC
LIMIT 100
