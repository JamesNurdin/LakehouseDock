WITH post_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(po.id) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM person p
    LEFT JOIN post po ON po.creator_person_id = p.id
    GROUP BY p.id
),
comment_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(co.id) AS comment_count,
        AVG(co.length) AS avg_comment_length
    FROM person p
    LEFT JOIN comment co ON co.creator_person_id = p.id
    GROUP BY p.id
),
friend_counts AS (
    SELECT
        pkp.person1_id AS person_id,
        COUNT(DISTINCT pkp.person2_id) AS friend_count
    FROM person_knows_person pkp
    GROUP BY pkp.person1_id
),
friend_post_counts AS (
    SELECT
        pkp.person1_id AS person_id,
        COUNT(DISTINCT po.id) AS friend_post_count
    FROM person_knows_person pkp
    JOIN person fp ON fp.id = pkp.person2_id
    JOIN post po ON po.creator_person_id = fp.id
    GROUP BY pkp.person1_id
),
person_info AS (
    SELECT
        id AS person_id,
        first_name,
        last_name
    FROM person
)
SELECT
    pi.person_id,
    pi.first_name,
    pi.last_name,
    COALESCE(ps.post_count, 0) AS post_count,
    ps.avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    cs.avg_comment_length,
    COALESCE(fc.friend_count, 0) AS friend_count,
    COALESCE(fpc.friend_post_count, 0) AS friend_post_count
FROM person_info pi
LEFT JOIN post_stats ps ON ps.person_id = pi.person_id
LEFT JOIN comment_stats cs ON cs.person_id = pi.person_id
LEFT JOIN friend_counts fc ON fc.person_id = pi.person_id
LEFT JOIN friend_post_counts fpc ON fpc.person_id = pi.person_id
ORDER BY post_count DESC
LIMIT 100
