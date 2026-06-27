SELECT
    t.production_year,
    COUNT(DISTINCT t.id) AS total_movies,
    COUNT(DISTINCT ci.id) AS total_cast_entries,
    COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN n.id END) AS male_cast,
    COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN n.id END) AS female_cast,
    COUNT(DISTINCT mk.id) AS total_keyword_entries,
    COUNT(DISTINCT mc.id) AS total_company_entries,
    COUNT(DISTINCT cn.id) AS total_character_entries,
    COUNT(DISTINCT mi.id) AS total_movie_info_entries,
    COUNT(DISTINCT it.id) AS total_distinct_info_types,
    CAST(COUNT(DISTINCT ci.id) AS DOUBLE) / NULLIF(COUNT(DISTINCT t.id), 0) AS avg_cast_per_movie,
    CAST(COUNT(DISTINCT mk.id) AS DOUBLE) / NULLIF(COUNT(DISTINCT t.id), 0) AS avg_keywords_per_movie,
    CAST(COUNT(DISTINCT mc.id) AS DOUBLE) / NULLIF(COUNT(DISTINCT t.id), 0) AS avg_companies_per_movie,
    CAST(COUNT(DISTINCT cn.id) AS DOUBLE) / NULLIF(COUNT(DISTINCT t.id), 0) AS avg_characters_per_movie,
    CAST(COUNT(DISTINCT mi.id) AS DOUBLE) / NULLIF(COUNT(DISTINCT t.id), 0) AS avg_info_entries_per_movie
FROM
    title t
LEFT JOIN cast_info ci ON ci.movie_id = t.id
LEFT JOIN name n ON n.id = ci.person_id
LEFT JOIN char_name cn ON cn.id = ci.person_role_id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
LEFT JOIN movie_info mi ON mi.movie_id = t.id
LEFT JOIN info_type it ON it.id = mi.info_type_id
WHERE
    t.production_year IS NOT NULL
GROUP BY
    t.production_year
ORDER BY
    t.production_year
