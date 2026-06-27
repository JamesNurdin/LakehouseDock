WITH persons_by_tag_class AS (
    SELECT DISTINCT p.id AS person_id,
           tc.id AS tag_class_id,
           tc.name AS tag_class_name
    FROM person p
    JOIN person_has_interest_tag pit ON pit.person_id = p.id
    JOIN tag t ON t.id = pit.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
),
comments_by_tag_class AS (
    SELECT pb.tag_class_id,
           COUNT(c.id) AS comment_cnt,
           SUM(c.length) AS total_comment_length,
           AVG(c.length) AS avg_comment_length
    FROM persons_by_tag_class pb
    JOIN comment c ON c.creator_person_id = pb.person_id
    GROUP BY pb.tag_class_id
),
likes_by_tag_class AS (
    SELECT pb.tag_class_id,
           COUNT(plp.post_id) AS liked_post_cnt,
           SUM(pst.length) AS total_liked_post_length,
           AVG(pst.length) AS avg_liked_post_length
    FROM persons_by_tag_class pb
    JOIN person_likes_post plp ON plp.person_id = pb.person_id
    JOIN post pst ON pst.id = plp.post_id
    JOIN post_has_tag_tag pht ON pht.post_id = pst.id
    JOIN tag t ON t.id = pht.tag_id
    WHERE t.type_tag_class_id = pb.tag_class_id
    GROUP BY pb.tag_class_id
)
SELECT tc.id AS tag_class_id,
       tc.name AS tag_class_name,
       COALESCE(cb.comment_cnt, 0) AS comment_count,
       COALESCE(cb.total_comment_length, 0) AS total_comment_length,
       COALESCE(cb.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(lb.liked_post_cnt, 0) AS liked_post_count,
       COALESCE(lb.total_liked_post_length, 0) AS total_liked_post_length,
       COALESCE(lb.avg_liked_post_length, 0) AS avg_liked_post_length
FROM tag_class tc
LEFT JOIN comments_by_tag_class cb ON cb.tag_class_id = tc.id
LEFT JOIN likes_by_tag_class lb ON lb.tag_class_id = tc.id
ORDER BY comment_count DESC
LIMIT 10
