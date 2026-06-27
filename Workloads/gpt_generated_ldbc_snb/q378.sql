WITH
    person_posts AS (
        SELECT
            p.creator_person_id AS person_id,
            COUNT(*) AS post_count,
            AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.creator_person_id
    ),
    post_likes AS (
        SELECT
            p.creator_person_id AS person_id,
            COUNT(*) AS post_likes_received
        FROM post p
        JOIN person_likes_post plp ON plp.post_id = p.id
        GROUP BY p.creator_person_id
    ),
    comment_counts AS (
        SELECT
            c.creator_person_id AS person_id,
            COUNT(*) AS comment_count,
            AVG(c.length) AS avg_comment_length
        FROM comment c
        GROUP BY c.creator_person_id
    ),
    comment_likes AS (
        SELECT
            c.creator_person_id AS person_id,
            COUNT(*) AS comment_likes_received
        FROM comment c
        JOIN person_likes_comment plc ON plc.comment_id = c.id
        GROUP BY c.creator_person_id
    ),
    friend_links AS (
        SELECT pk.person1_id AS person_id, pk.person2_id AS friend_id
        FROM person_knows_person pk
        UNION
        SELECT pk.person2_id AS person_id, pk.person1_id AS friend_id
        FROM person_knows_person pk
    ),
    friend_counts AS (
        SELECT
            person_id,
            COUNT(DISTINCT friend_id) AS friend_count
        FROM friend_links
        GROUP BY person_id
    ),
    interest_tags AS (
        SELECT
            person_id,
            COUNT(DISTINCT tag_id) AS interest_tag_count
        FROM person_has_interest_tag
        GROUP BY person_id
    )
SELECT
    per.id AS person_id,
    per.first_name,
    per.last_name,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pl.post_likes_received, 0) AS post_likes_received,
    COALESCE(cl.comment_likes_received, 0) AS comment_likes_received,
    COALESCE(pl.post_likes_received, 0) + COALESCE(cl.comment_likes_received, 0) AS total_likes_received,
    COALESCE(fc.friend_count, 0) AS friend_count,
    COALESCE(i.interest_tag_count, 0) AS interest_tag_count
FROM person per
LEFT JOIN person_posts p ON p.person_id = per.id
LEFT JOIN post_likes pl ON pl.person_id = per.id
LEFT JOIN comment_counts c ON c.person_id = per.id
LEFT JOIN comment_likes cl ON cl.person_id = per.id
LEFT JOIN friend_counts fc ON fc.person_id = per.id
LEFT JOIN interest_tags i ON i.person_id = per.id
ORDER BY total_likes_received DESC
LIMIT 100
