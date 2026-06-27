WITH friend_pairs AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS friend_pair_count
    FROM person_knows_person pk
    JOIN person p1 ON p1.id = pk.person1_id
    JOIN person_has_interest_tag phi1 ON phi1.person_id = p1.id
    JOIN tag t ON t.id = phi1.tag_id
    JOIN person p2 ON p2.id = pk.person2_id
    JOIN person_has_interest_tag phi2 ON phi2.person_id = p2.id AND phi2.tag_id = t.id
    GROUP BY t.id, t.name
),
posts_by_tag AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(po.id) AS total_posts,
        AVG(po.length) AS avg_post_length
    FROM person_has_interest_tag phi
    JOIN person p ON p.id = phi.person_id
    JOIN post po ON po.creator_person_id = p.id
    JOIN tag t ON t.id = phi.tag_id
    GROUP BY t.id, t.name
)
SELECT
    fp.tag_id,
    fp.tag_name,
    fp.friend_pair_count,
    pb.total_posts,
    pb.avg_post_length
FROM friend_pairs fp
LEFT JOIN posts_by_tag pb
    ON pb.tag_id = fp.tag_id
   AND pb.tag_name = fp.tag_name
ORDER BY fp.friend_pair_count DESC
LIMIT 10
