WITH friend_counts AS (
    SELECT person_id,
           COUNT(DISTINCT friend_id) AS num_friends
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    )
    GROUP BY person_id
),
post_stats AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS num_posts,
           SUM(length) AS total_post_length,
           AVG(length) AS avg_post_length
    FROM post
    GROUP BY creator_person_id
),
post_like_counts AS (
    SELECT p.creator_person_id AS person_id,
           COUNT(*) AS post_likes_received
    FROM post p
    JOIN person_likes_post plp ON p.id = plp.post_id
    GROUP BY p.creator_person_id
),
comment_stats AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS num_comments,
           SUM(length) AS total_comment_length,
           AVG(length) AS avg_comment_length
    FROM comment
    GROUP BY creator_person_id
),
comment_like_counts AS (
    SELECT c.creator_person_id AS person_id,
           COUNT(*) AS comment_likes_received
    FROM comment c
    JOIN person_likes_comment plc ON c.id = plc.comment_id
    GROUP BY c.creator_person_id
),
forum_member_counts AS (
    SELECT person_id,
           COUNT(DISTINCT forum_id) AS num_forums_member
    FROM forum_has_member_person
    GROUP BY person_id
),
university_counts AS (
    SELECT person_id,
           COUNT(DISTINCT university_id) AS num_universities
    FROM person_study_at_university
    GROUP BY person_id
),
company_counts AS (
    SELECT person_id,
           COUNT(DISTINCT company_id) AS num_companies
    FROM person_work_at_company
    GROUP BY person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    p.email,
    pl.name AS city_name,
    COALESCE(ps.num_posts, 0) AS num_posts,
    COALESCE(ps.total_post_length, 0) AS total_post_length,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.num_comments, 0) AS num_comments,
    COALESCE(cs.total_comment_length, 0) AS total_comment_length,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(plc.post_likes_received, 0) AS post_likes_received,
    COALESCE(clc.comment_likes_received, 0) AS comment_likes_received,
    COALESCE(plc.post_likes_received, 0) + COALESCE(clc.comment_likes_received, 0) AS total_likes_received,
    COALESCE(fm.num_forums_member, 0) AS num_forums_member,
    COALESCE(fc.num_friends, 0) AS num_friends,
    COALESCE(uc.num_universities, 0) AS num_universities,
    COALESCE(cc.num_companies, 0) AS num_companies
FROM person p
LEFT JOIN place pl ON p.location_city_id = pl.id
LEFT JOIN post_stats ps ON p.id = ps.person_id
LEFT JOIN post_like_counts plc ON p.id = plc.person_id
LEFT JOIN comment_stats cs ON p.id = cs.person_id
LEFT JOIN comment_like_counts clc ON p.id = clc.person_id
LEFT JOIN forum_member_counts fm ON p.id = fm.person_id
LEFT JOIN friend_counts fc ON p.id = fc.person_id
LEFT JOIN university_counts uc ON p.id = uc.person_id
LEFT JOIN company_counts cc ON p.id = cc.person_id
ORDER BY total_likes_received DESC
LIMIT 10
