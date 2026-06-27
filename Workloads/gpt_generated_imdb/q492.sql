WITH movie_base AS (
    SELECT t.id AS movie_id,
           t.title,
           kt.kind AS kind,
           t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),

actor_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS actor_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),

male_actor_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS male_actor_cnt
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    WHERE n.gender = 'M'
    GROUP BY ci.movie_id
),

female_actor_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS female_actor_cnt
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    WHERE n.gender = 'F'
    GROUP BY ci.movie_id
),

company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),

keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),

info_counts AS (
    SELECT mi.movie_id,
           COUNT(DISTINCT mi.info_type_id) AS info_type_cnt
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    mb.kind,
    COUNT(*) AS movie_count,
    COALESCE(SUM(ac.actor_cnt), 0) AS total_actors,
    COALESCE(SUM(mac.male_actor_cnt), 0) AS male_actors,
    COALESCE(SUM(fac.female_actor_cnt), 0) AS female_actors,
    COALESCE(SUM(cc.company_cnt), 0) AS total_companies,
    COALESCE(AVG(kc.keyword_cnt), 0) AS avg_keywords_per_movie,
    COALESCE(AVG(ic.info_type_cnt), 0) AS avg_info_types_per_movie,
    MIN(mb.production_year) AS earliest_year
FROM movie_base mb
LEFT JOIN actor_counts ac ON ac.movie_id = mb.movie_id
LEFT JOIN male_actor_counts mac ON mac.movie_id = mb.movie_id
LEFT JOIN female_actor_counts fac ON fac.movie_id = mb.movie_id
LEFT JOIN company_counts cc ON cc.movie_id = mb.movie_id
LEFT JOIN keyword_counts kc ON kc.movie_id = mb.movie_id
LEFT JOIN info_counts ic ON ic.movie_id = mb.movie_id
GROUP BY mb.kind
ORDER BY movie_count DESC
