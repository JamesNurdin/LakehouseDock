WITH
    post_agg AS (
        SELECT p.creator_person_id AS person_id,
               COUNT(*) AS post_count,
               AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.creator_person_id
    ),
    comment_agg AS (
        SELECT c.creator_person_id AS person_id,
               COUNT(*) AS comment_count,
               AVG(c.length) AS avg_comment_length
        FROM comment c
        GROUP BY c.creator_person_id
    ),
    likes_given_comment AS (
        SELECT plc.person_id,
               COUNT(*) AS likes_given_comment
        FROM person_likes_comment plc
        GROUP BY plc.person_id
    ),
    likes_given_post AS (
        SELECT plp.person_id,
               COUNT(*) AS likes_given_post
        FROM person_likes_post plp
        GROUP BY plp.person_id
    ),
    likes_received_comment AS (
        SELECT c.creator_person_id AS person_id,
               COUNT(*) AS likes_received_comment
        FROM comment c
        JOIN person_likes_comment plc ON plc.comment_id = c.id
        GROUP BY c.creator_person_id
    ),
    likes_received_post AS (
        SELECT p.creator_person_id AS person_id,
               COUNT(*) AS likes_received_post
        FROM post p
        JOIN person_likes_post plp ON plp.post_id = p.id
        GROUP BY p.creator_person_id
    ),
    interest_tag_count AS (
        SELECT pit.person_id,
               COUNT(DISTINCT pit.tag_id) AS interest_tag_count
        FROM person_has_interest_tag pit
        GROUP BY pit.person_id
    ),
    post_tag_count AS (
        SELECT p.creator_person_id AS person_id,
               COUNT(DISTINCT pht.tag_id) AS post_tag_count
        FROM post p
        JOIN post_has_tag_tag pht ON pht.post_id = p.id
        GROUP BY p.creator_person_id
    ),
    comment_tag_count AS (
        SELECT c.creator_person_id AS person_id,
               COUNT(DISTINCT cht.tag_id) AS comment_tag_count
        FROM comment c
        JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
        GROUP BY c.creator_person_id
    )
SELECT
    per.id AS person_id,
    per.first_name,
    per.last_name,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(pa.avg_post_length, 0) AS avg_post_length,
    COALESCE(ca.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(lgc.likes_given_comment, 0) AS likes_given_comment,
    COALESCE(lgp.likes_given_post, 0) AS likes_given_post,
    COALESCE(lrc.likes_received_comment, 0) AS likes_received_comment,
    COALESCE(lrp.likes_received_post, 0) AS likes_received_post,
    COALESCE(itc.interest_tag_count, 0) AS interest_tag_count,
    COALESCE(ptc.post_tag_count, 0) AS post_tag_count,
    COALESCE(ctc.comment_tag_count, 0) AS comment_tag_count,
    (COALESCE(lrc.likes_received_comment, 0) + COALESCE(lrp.likes_received_post, 0)) AS total_likes_received,
    (COALESCE(lgc.likes_given_comment, 0) + COALESCE(lgp.likes_given_post, 0)) AS total_likes_given
FROM person per
LEFT JOIN post_agg pa ON pa.person_id = per.id
LEFT JOIN comment_agg ca ON ca.person_id = per.id
LEFT JOIN likes_given_comment lgc ON lgc.person_id = per.id
LEFT JOIN likes_given_post lgp ON lgp.person_id = per.id
LEFT JOIN likes_received_comment lrc ON lrc.person_id = per.id
LEFT JOIN likes_received_post lrp ON lrp.person_id = per.id
LEFT JOIN interest_tag_count itc ON itc.person_id = per.id
LEFT JOIN post_tag_count ptc ON ptc.person_id = per.id
LEFT JOIN comment_tag_count ctc ON ctc.person_id = per.id
ORDER BY total_likes_received DESC
LIMIT 20
