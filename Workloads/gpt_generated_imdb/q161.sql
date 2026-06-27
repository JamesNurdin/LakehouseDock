WITH
    movie_basic AS (
        SELECT t.id AS movie_id,
               t.title,
               t.production_year,
               kt.kind
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
    ),
    rating_info AS (
        SELECT mi.movie_id,
               CAST(mi.info AS double) AS rating
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'rating'
    ),
    rating_agg AS (
        SELECT movie_id,
               MAX(rating) AS rating
        FROM rating_info
        GROUP BY movie_id
    ),
    cast_counts AS (
        SELECT ci.movie_id,
               COUNT(DISTINCT ci.person_id) AS cast_count,
               COUNT(DISTINCT ci.person_role_id) AS character_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    company_counts AS (
        SELECT mc.movie_id,
               COUNT(DISTINCT mc.company_id) AS company_count,
               SUM(CASE WHEN ct.kind = 'production' THEN 1 ELSE 0 END) AS production_company_count,
               SUM(CASE WHEN ct.kind = 'distribution' THEN 1 ELSE 0 END) AS distribution_company_count
        FROM movie_companies mc
        JOIN company_type ct ON mc.company_type_id = ct.id
        GROUP BY mc.movie_id
    ),
    keyword_agg AS (
        SELECT mk.movie_id,
               ARRAY_AGG(k.keyword ORDER BY k.keyword) AS keywords
        FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
        GROUP BY mk.movie_id
    )
SELECT mb.title,
       mb.production_year,
       mb.kind,
       ra.rating,
       cc.cast_count,
       cc.character_count,
       comc.company_count,
       comc.production_company_count,
       comc.distribution_company_count,
       kw.keywords,
       CARDINALITY(kw.keywords) AS keyword_count
FROM movie_basic mb
LEFT JOIN rating_agg ra ON mb.movie_id = ra.movie_id
LEFT JOIN cast_counts cc ON mb.movie_id = cc.movie_id
LEFT JOIN company_counts comc ON mb.movie_id = comc.movie_id
LEFT JOIN keyword_agg kw ON mb.movie_id = kw.movie_id
WHERE mb.kind = 'movie'
  AND mb.production_year >= 2000
ORDER BY mb.production_year DESC, mb.title
LIMIT 100
