WITH person_city AS (
    SELECT
        p.id AS person_id,
        p.gender,
        p.location_city_id,
        pl.name AS city_name,
        p.language
    FROM person p
    JOIN place pl ON p.location_city_id = pl.id
),
forum_counts AS (
    SELECT
        person_id,
        COUNT(*) AS forum_memberships
    FROM forum_has_member_person
    GROUP BY person_id
),
comment_likes_counts AS (
    SELECT
        person_id,
        COUNT(*) AS liked_comments
    FROM person_likes_comment
    GROUP BY person_id
),
interest_counts AS (
    SELECT
        person_id,
        COUNT(*) AS interest_tags
    FROM person_has_interest_tag
    GROUP BY person_id
),
work_counts AS (
    SELECT
        person_id,
        COUNT(DISTINCT company_id) AS distinct_companies
    FROM person_work_at_company
    GROUP BY person_id
),
study_counts AS (
    SELECT
        person_id,
        COUNT(DISTINCT university_id) AS distinct_universities
    FROM person_study_at_university
    GROUP BY person_id
)
SELECT
    pc.city_name,
    COUNT(*) AS total_persons,
    AVG(COALESCE(fc.forum_memberships, 0)) AS avg_forum_memberships,
    AVG(COALESCE(clc.liked_comments, 0)) AS avg_liked_comments,
    AVG(COALESCE(ic.interest_tags, 0)) AS avg_interest_tags,
    AVG(COALESCE(wc.distinct_companies, 0)) AS avg_distinct_companies,
    AVG(COALESCE(sc.distinct_universities, 0)) AS avg_distinct_universities
FROM person_city pc
LEFT JOIN forum_counts fc ON pc.person_id = fc.person_id
LEFT JOIN comment_likes_counts clc ON pc.person_id = clc.person_id
LEFT JOIN interest_counts ic ON pc.person_id = ic.person_id
LEFT JOIN work_counts wc ON pc.person_id = wc.person_id
LEFT JOIN study_counts sc ON pc.person_id = sc.person_id
WHERE pc.language = 'English'
GROUP BY pc.city_name
ORDER BY total_persons DESC
LIMIT 20
