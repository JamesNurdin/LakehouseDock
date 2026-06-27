WITH
    comments_created AS (
        SELECT
            creator_person_id AS person_id,
            COUNT(*) AS total_comments_created,
            AVG(length) AS avg_comment_length,
            SUM(CASE WHEN parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS total_comments_replied
        FROM comment
        GROUP BY creator_person_id
    ),
    likes_given AS (
        SELECT
            person_id,
            COUNT(*) AS total_comments_liked
        FROM person_likes_comment
        GROUP BY person_id
    ),
    likes_received AS (
        SELECT
            c.creator_person_id AS person_id,
            COUNT(plc.person_id) AS total_likes_received
        FROM comment c
        JOIN person_likes_comment plc ON plc.comment_id = c.id
        GROUP BY c.creator_person_id
    ),
    friends AS (
        SELECT
            pkp.person_id,
            COUNT(DISTINCT pkp.friend_id) AS total_friends
        FROM (
            SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
            UNION ALL
            SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
        ) pkp
        GROUP BY pkp.person_id
    ),
    universities AS (
        SELECT
            person_id,
            COUNT(DISTINCT university_id) AS total_universities
        FROM person_study_at_university
        GROUP BY person_id
    ),
    companies AS (
        SELECT
            person_id,
            COUNT(DISTINCT company_id) AS total_companies
        FROM person_work_at_company
        GROUP BY person_id
    ),
    forums_mod AS (
        SELECT
            moderator_person_id AS person_id,
            COUNT(*) AS total_forums_moderated
        FROM forum
        GROUP BY moderator_person_id
    )
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(cc.total_comments_created, 0) AS total_comments_created,
    COALESCE(cc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cc.total_comments_replied, 0) AS total_comments_replied,
    COALESCE(lg.total_comments_liked, 0) AS total_comments_liked,
    COALESCE(lr.total_likes_received, 0) AS total_likes_received,
    COALESCE(f.total_friends, 0) AS total_friends,
    COALESCE(u.total_universities, 0) AS total_universities,
    COALESCE(c.total_companies, 0) AS total_companies,
    COALESCE(fm.total_forums_moderated, 0) AS total_forums_moderated,
    CASE
        WHEN COALESCE(cc.total_comments_created, 0) > 0 THEN COALESCE(lr.total_likes_received, 0) * 1.0 / COALESCE(cc.total_comments_created, 1)
        ELSE 0
    END AS avg_likes_per_comment
FROM person p
LEFT JOIN comments_created cc ON cc.person_id = p.id
LEFT JOIN likes_given lg ON lg.person_id = p.id
LEFT JOIN likes_received lr ON lr.person_id = p.id
LEFT JOIN friends f ON f.person_id = p.id
LEFT JOIN universities u ON u.person_id = p.id
LEFT JOIN companies c ON c.person_id = p.id
LEFT JOIN forums_mod fm ON fm.person_id = p.id
ORDER BY total_comments_created DESC, total_likes_received DESC
LIMIT 100
