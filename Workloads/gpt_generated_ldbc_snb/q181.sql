WITH comment_stats AS (
    SELECT
        creator_person_id AS person_id,
        COUNT(*) AS comment_count,
        SUM(length) AS total_comment_length,
        AVG(length) AS avg_comment_length
    FROM comment
    GROUP BY creator_person_id
),
like_stats AS (
    SELECT
        person_id,
        COUNT(*) AS likes_given,
        COUNT(DISTINCT comment_id) AS distinct_comments_liked
    FROM person_likes_comment
    GROUP BY person_id
),
friend_stats AS (
    SELECT
        person_id,
        COUNT(DISTINCT friend_id) AS friend_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) t
    GROUP BY person_id
),
forum_stats AS (
    SELECT
        person_id,
        COUNT(DISTINCT forum_id) AS forum_membership_count
    FROM forum_has_member_person
    GROUP BY person_id
),
university_stats AS (
    SELECT
        person_id,
        COUNT(DISTINCT university_id) AS university_count
    FROM person_study_at_university
    GROUP BY person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_length, 0) AS total_comment_length,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ls.likes_given, 0) AS likes_given,
    COALESCE(ls.distinct_comments_liked, 0) AS distinct_comments_liked,
    COALESCE(fs.friend_count, 0) AS friend_count,
    COALESCE(fms.forum_membership_count, 0) AS forum_membership_count,
    COALESCE(us.university_count, 0) AS university_count
FROM person p
LEFT JOIN comment_stats cs ON cs.person_id = p.id
LEFT JOIN like_stats ls ON ls.person_id = p.id
LEFT JOIN friend_stats fs ON fs.person_id = p.id
LEFT JOIN forum_stats fms ON fms.person_id = p.id
LEFT JOIN university_stats us ON us.person_id = p.id
ORDER BY comment_count DESC, likes_given DESC
LIMIT 100
