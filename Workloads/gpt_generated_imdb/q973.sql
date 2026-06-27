WITH
c_cast AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS num_cast
    FROM cast_info ci
    GROUP BY ci.movie_id
),
c_keywords AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS num_keywords
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
c_companies AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS num_companies
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
c_ratings AS (
    SELECT mi.movie_id,
           AVG(CAST(mi.info AS double)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
),
c_aka AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT a.id) AS num_aka_names
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN aka_name a ON a.person_id = n.id
    GROUP BY ci.movie_id
),
c_characters AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT cn.id) AS num_characters
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.movie_id
)
SELECT
    t.title,
    t.production_year,
    k.kind,
    COALESCE(c_cast.num_cast, 0)        AS num_cast,
    COALESCE(c_keywords.num_keywords, 0) AS num_keywords,
    COALESCE(c_companies.num_companies, 0) AS num_companies,
    COALESCE(c_aka.num_aka_names, 0)   AS num_aka_names,
    COALESCE(c_characters.num_characters, 0) AS num_characters,
    COALESCE(c_ratings.avg_rating, 0)   AS avg_rating
FROM title t
JOIN kind_type k ON t.kind_id = k.id
LEFT JOIN c_cast       ON c_cast.movie_id       = t.id
LEFT JOIN c_keywords   ON c_keywords.movie_id   = t.id
LEFT JOIN c_companies  ON c_companies.movie_id  = t.id
LEFT JOIN c_aka        ON c_aka.movie_id        = t.id
LEFT JOIN c_characters ON c_characters.movie_id = t.id
LEFT JOIN c_ratings    ON c_ratings.movie_id    = t.id
WHERE t.production_year >= 2000
ORDER BY avg_rating DESC NULLS LAST
LIMIT 10
