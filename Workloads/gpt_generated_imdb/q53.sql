WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mi.id) AS info_count,
        COUNT(DISTINCT a.id) AS aka_name_count,
        COUNT(DISTINCT cn.id) AS role_count
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN name n ON n.id = ci.person_id
    LEFT JOIN aka_name a ON a.person_id = n.id
    LEFT JOIN char_name cn ON cn.id = ci.person_role_id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
    HAVING COUNT(DISTINCT ci.person_id) >= 10
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    total_cast,
    male_cast,
    female_cast,
    company_count,
    keyword_count,
    info_count,
    aka_name_count,
    role_count,
    RANK() OVER (ORDER BY total_cast DESC) AS cast_rank
FROM movie_stats
ORDER BY total_cast DESC
LIMIT 20
