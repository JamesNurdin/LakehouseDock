SELECT
    kt.kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS num_titles,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_title,
    AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_title,
    COUNT(DISTINCT gi.genre) AS distinct_genre_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
) cc ON t.id = cc.movie_id
LEFT JOIN (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
) compc ON t.id = compc.movie_id
LEFT JOIN (
    SELECT
        mi.movie_id,
        mi.info AS genre
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
) gi ON t.id = gi.movie_id
WHERE t.production_year >= 1990 AND t.production_year <= 2000
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
