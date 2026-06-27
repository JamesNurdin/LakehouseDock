WITH movie_cast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast,
        COUNT(DISTINCT cn.id) AS distinct_characters
    FROM cast_info ci
    LEFT JOIN name n ON ci.person_id = n.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.movie_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_companies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COALESCE(c.total_cast, 0) AS total_cast,
        COALESCE(c.male_cast, 0) AS male_cast,
        COALESCE(c.female_cast, 0) AS female_cast,
        COALESCE(c.distinct_characters, 0) AS distinct_characters,
        COALESCE(k.keyword_count, 0) AS keyword_count,
        COALESCE(comp.company_count, 0) AS company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_cast c ON c.movie_id = t.id
    LEFT JOIN movie_keywords k ON k.movie_id = t.id
    LEFT JOIN movie_companies comp ON comp.movie_id = t.id
    WHERE t.production_year IS NOT NULL
)
SELECT
    production_year,
    kind,
    COUNT(*) AS movie_count,
    AVG(total_cast) AS avg_cast_per_movie,
    AVG(male_cast) AS avg_male_cast_per_movie,
    AVG(female_cast) AS avg_female_cast_per_movie,
    AVG(distinct_characters) AS avg_characters_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(company_count) AS avg_companies_per_movie
FROM movie_details
GROUP BY production_year, kind
ORDER BY production_year DESC, kind
