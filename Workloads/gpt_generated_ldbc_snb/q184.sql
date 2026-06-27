WITH person_friends AS (
    SELECT
        pk.person1_id AS person_id,
        COUNT(DISTINCT pk.person2_id) AS friend_cnt
    FROM person_knows_person pk
    GROUP BY pk.person1_id
),
comment_likes AS (
    SELECT
        plc.comment_id,
        COUNT(*) AS like_cnt
    FROM person_likes_comment plc
    GROUP BY plc.comment_id
)
SELECT
    pht.tag_id,
    COUNT(DISTINCT p.id) AS person_count,
    AVG(COALESCE(pf.friend_cnt, 0)) AS avg_friends_per_person,
    COUNT(DISTINCT c.id) AS comment_count,
    AVG(c.length) AS avg_comment_length,
    AVG(COALESCE(cl.like_cnt, 0)) AS avg_likes_per_comment
FROM person_has_interest_tag pht
JOIN person p ON pht.person_id = p.id
LEFT JOIN person_friends pf ON pf.person_id = p.id
LEFT JOIN comment c ON c.creator_person_id = p.id
LEFT JOIN comment_likes cl ON cl.comment_id = c.id
GROUP BY pht.tag_id
ORDER BY comment_count DESC
LIMIT 10
