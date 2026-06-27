WITH post_stats AS (
    SELECT pht.tag_id,
           COUNT(DISTINCT pht.post_id) AS post_cnt,
           AVG(p.length) AS avg_post_length,
           COUNT(DISTINCT p.creator_person_id) AS creator_cnt
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    GROUP BY pht.tag_id
),
forum_stats AS (
    SELECT fht.tag_id,
           COUNT(DISTINCT fht.forum_id) AS forum_cnt
    FROM forum_has_tag_tag fht
    GROUP BY fht.tag_id
),
comment_stats AS (
    SELECT cht.tag_id,
           COUNT(DISTINCT cht.comment_id) AS comment_cnt
    FROM comment_has_tag_tag cht
    GROUP BY cht.tag_id
),
interest_stats AS (
    SELECT phi.tag_id,
           COUNT(DISTINCT phi.person_id) AS interest_cnt
    FROM person_has_interest_tag phi
    GROUP BY phi.tag_id
)
SELECT t.id AS tag_id,
       t.name AS tag_name,
       tc.name AS tag_class_name,
       COALESCE(ps.post_cnt, 0) AS post_cnt,
       COALESCE(ps.avg_post_length, 0) AS avg_post_length,
       COALESCE(ps.creator_cnt, 0) AS creator_cnt,
       COALESCE(fs.forum_cnt, 0) AS forum_cnt,
       COALESCE(cs.comment_cnt, 0) AS comment_cnt,
       COALESCE(ints.interest_cnt, 0) AS interest_cnt
FROM tag t
LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
LEFT JOIN post_stats ps ON t.id = ps.tag_id
LEFT JOIN forum_stats fs ON t.id = fs.tag_id
LEFT JOIN comment_stats cs ON t.id = cs.tag_id
LEFT JOIN interest_stats ints ON t.id = ints.tag_id
ORDER BY post_cnt DESC
LIMIT 100
