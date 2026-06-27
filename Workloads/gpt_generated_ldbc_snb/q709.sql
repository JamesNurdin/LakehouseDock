/*
  Analytical query: per gender, compute counts and averages of social activity and forum moderation.
  Uses only the selected tables and respects the allowed join relationships.
*/
WITH
    connections AS (
        SELECT
            person_id,
            SUM(conn_count) AS total_connections
        FROM (
            SELECT
                person1_id AS person_id,
                COUNT(*) AS conn_count
            FROM person_knows_person
            GROUP BY person1_id
            UNION ALL
            SELECT
                person2_id AS person_id,
                COUNT(*) AS conn_count
            FROM person_knows_person
            GROUP BY person2_id
        ) t
        GROUP BY person_id
    ),
    likes_posts AS (
        SELECT
            person_id,
            COUNT(*) AS likes_posts
        FROM person_likes_post
        GROUP BY person_id
    ),
    likes_comments AS (
        SELECT
            person_id,
            COUNT(*) AS likes_comments
        FROM person_likes_comment
        GROUP BY person_id
    ),
    studies AS (
        SELECT
            person_id,
            COUNT(DISTINCT university_id) AS num_universities
        FROM person_study_at_university
        GROUP BY person_id
    ),
    work AS (
        SELECT
            person_id,
            COUNT(DISTINCT company_id) AS num_companies
        FROM person_work_at_company
        GROUP BY person_id
    ),
    forum_mods AS (
        SELECT
            moderator_person_id AS person_id,
            COUNT(*) AS forums_moderated
        FROM forum
        GROUP BY moderator_person_id
    )
SELECT
    p.gender,
    COUNT(DISTINCT p.id) AS person_count,
    AVG(COALESCE(c.total_connections, 0)) AS avg_connections,
    AVG(COALESCE(lp.likes_posts, 0)) AS avg_likes_posts,
    AVG(COALESCE(lc.likes_comments, 0)) AS avg_likes_comments,
    AVG(COALESCE(s.num_universities, 0)) AS avg_universities,
    AVG(COALESCE(w.num_companies, 0)) AS avg_companies,
    AVG(COALESCE(fm.forums_moderated, 0)) AS avg_forums_moderated
FROM person p
LEFT JOIN connections c ON c.person_id = p.id
LEFT JOIN likes_posts lp ON lp.person_id = p.id
LEFT JOIN likes_comments lc ON lc.person_id = p.id
LEFT JOIN studies s ON s.person_id = p.id
LEFT JOIN work w ON w.person_id = p.id
LEFT JOIN forum_mods fm ON fm.person_id = p.id
GROUP BY p.gender
ORDER BY p.gender
