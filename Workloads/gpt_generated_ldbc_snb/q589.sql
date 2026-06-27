SELECT
    pht.tag_id,
    COUNT(*) AS interest_occurrences,
    COUNT(DISTINCT p.id) AS person_count,
    MIN(p.creation_date) AS earliest_interest_date,
    MAX(p.creation_date) AS latest_interest_date,
    COUNT(DISTINCT p.browser_used) AS distinct_browsers,
    SUM(CASE WHEN p.gender = 'male' THEN 1 ELSE 0 END) AS male_persons,
    SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_persons
FROM person_has_interest_tag pht
JOIN person p
    ON pht.person_id = p.id
WHERE p.language = 'English'
GROUP BY pht.tag_id
ORDER BY interest_occurrences DESC
LIMIT 50
