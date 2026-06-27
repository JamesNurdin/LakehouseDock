WITH movie_details AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.kind,
        COUNT(DISTINCT ci.person_id) AS cast_member_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count,
        COUNT(DISTINCT mi_idx.info_type_id) AS info_idx_type_count,
        AVG(t.production_year) AS avg_production_year
    FROM title t
    LEFT JOIN kind_type k
        ON t.kind_id = k.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN movie_info_idx mi_idx
        ON mi_idx.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, k.kind
)
SELECT
    kind,
    COUNT(*) AS total_movies,
    SUM(cast_member_count) AS total_cast_members,
    AVG(cast_member_count) AS avg_cast_per_movie,
    SUM(keyword_count) AS total_keywords,
    AVG(keyword_count) AS avg_keywords_per_movie,
    SUM(info_type_count) AS total_info_types,
    SUM(info_idx_type_count) AS total_info_idx_types,
    AVG(avg_production_year) AS avg_production_year
FROM movie_details
WHERE production_year >= 2000
GROUP BY kind
ORDER BY total_movies DESC
