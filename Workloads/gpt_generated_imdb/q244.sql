WITH movies_by_year AS (
    SELECT title.production_year AS year,
           count(DISTINCT title.id) AS movie_count
    FROM title
    WHERE title.production_year IS NOT NULL
    GROUP BY title.production_year
),
cast_by_year AS (
    SELECT title.production_year AS year,
           count(DISTINCT cast_info.person_id) AS distinct_cast_persons,
           count(cast_info.id) AS total_cast_entries
    FROM cast_info
    JOIN title ON cast_info.movie_id = title.id
    WHERE title.production_year IS NOT NULL
    GROUP BY title.production_year
),
keyword_by_year AS (
    SELECT title.production_year AS year,
           count(DISTINCT movie_keyword.keyword_id) AS distinct_keywords
    FROM movie_keyword
    JOIN title ON movie_keyword.movie_id = title.id
    WHERE title.production_year IS NOT NULL
    GROUP BY title.production_year
),
info_by_year AS (
    SELECT title.production_year AS year,
           count(DISTINCT info_type.info) AS distinct_info_type_names,
           count(movie_info.id) AS total_info_entries
    FROM movie_info
    JOIN title ON movie_info.movie_id = title.id
    JOIN info_type ON movie_info.info_type_id = info_type.id
    WHERE title.production_year IS NOT NULL
    GROUP BY title.production_year
)
SELECT m.year,
       m.movie_count,
       c.distinct_cast_persons,
       c.total_cast_entries,
       k.distinct_keywords,
       i.distinct_info_type_names,
       i.total_info_entries
FROM movies_by_year m
LEFT JOIN cast_by_year c ON m.year = c.year
LEFT JOIN keyword_by_year k ON m.year = k.year
LEFT JOIN info_by_year i ON m.year = i.year
ORDER BY m.year
