SELECT
    country.name AS country_name,
    COUNT(comment.id) AS total_comments,
    AVG(comment.length) AS avg_comment_length,
    COUNT(DISTINCT person.id) AS distinct_commenters,
    COUNT(DISTINCT company.id) AS distinct_companies,
    COUNT(DISTINCT university.id) AS distinct_universities,
    SUM(CASE WHEN comment.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS reply_comments,
    CAST(SUM(CASE WHEN comment.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS double) / COUNT(comment.id) AS reply_rate
FROM comment
JOIN person ON comment.creator_person_id = person.id
JOIN place AS country ON comment.location_country_id = country.id
LEFT JOIN person_work_at_company pwc ON pwc.person_id = person.id
LEFT JOIN organisation AS company ON pwc.company_id = company.id AND company.type = 'Company'
LEFT JOIN person_study_at_university psu ON psu.person_id = person.id
LEFT JOIN organisation AS university ON psu.university_id = university.id AND university.type = 'University'
GROUP BY country.name
ORDER BY total_comments DESC
LIMIT 20
