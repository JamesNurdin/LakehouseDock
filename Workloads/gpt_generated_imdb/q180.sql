/*
  Analytical query: For each title kind (e.g., movie, short, TV series) compute
  - number of titles released between 2000 and 2020
  - average number of distinct cast members per title
  - average number of distinct keywords per title
  - average number of distinct info‑type entries per title (from movie_info)
  - earliest and latest production year for the kind
  - a rank of the kind by total title count
*/
WITH per_movie AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id)      AS cast_members,
        COUNT(DISTINCT mk.keyword_id)    AS keyword_count,
        COUNT(DISTINCT mi.info_type_id)  AS info_type_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci   ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi   ON mi.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
aggregated AS (
    SELECT
        kind,
        COUNT(*)                     AS num_movies,
        AVG(cast_members)            AS avg_cast_members,
        AVG(keyword_count)           AS avg_keywords,
        AVG(info_type_count)         AS avg_info_types,
        MIN(production_year)         AS earliest_year,
        MAX(production_year)         AS latest_year
    FROM per_movie
    GROUP BY kind
)
SELECT
    kind,
    num_movies,
    avg_cast_members,
    avg_keywords,
    avg_info_types,
    earliest_year,
    latest_year,
    RANK() OVER (ORDER BY num_movies DESC) AS kind_rank
FROM aggregated
ORDER BY num_movies DESC
