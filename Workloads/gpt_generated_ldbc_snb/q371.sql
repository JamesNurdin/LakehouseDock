WITH friend_counts AS (
    SELECT pkp.person1_id AS person_id, pkp.person2_id AS friend_id
    FROM person_knows_person pkp
    UNION ALL
    SELECT pkp.person2_id AS person_id, pkp.person1_id AS friend_id
    FROM person_knows_person pkp
),
friend_agg AS (
    SELECT person_id, COUNT(DISTINCT friend_id) AS friend_count
    FROM friend_counts
    GROUP BY person_id
),
like_agg AS (
    SELECT person_id, COUNT(DISTINCT comment_id) AS liked_comments
    FROM person_likes_comment
    GROUP BY person_id
),
comment_agg AS (
    SELECT creator_person_id AS person_id, COUNT(*) AS comments_authored
    FROM comment
    GROUP BY creator_person_id
),
post_agg AS (
    SELECT creator_person_id AS person_id, COUNT(*) AS posts_authored
    FROM post
    GROUP BY creator_person_id
),
university_agg AS (
    SELECT psu.person_id, COUNT(DISTINCT org.id) AS university_count
    FROM person_study_at_university psu
    JOIN organisation org ON psu.university_id = org.id
    GROUP BY psu.person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(fa.friend_count, 0) AS friend_count,
    COALESCE(la.liked_comments, 0) AS liked_comments,
    COALESCE(ca.comments_authored, 0) AS comments_authored,
    COALESCE(pa.posts_authored, 0) AS posts_authored,
    COALESCE(ua.university_count, 0) AS university_count
FROM person p
LEFT JOIN friend_agg fa ON fa.person_id = p.id
LEFT JOIN like_agg la ON la.person_id = p.id
LEFT JOIN comment_agg ca ON ca.person_id = p.id
LEFT JOIN post_agg pa ON pa.person_id = p.id
LEFT JOIN university_agg ua ON ua.person_id = p.id
ORDER BY friend_count DESC, liked_comments DESC
LIMIT 10
