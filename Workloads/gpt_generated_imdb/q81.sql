/*
  Analytical query on the IMDB dataset (Trino syntax).
  For each male person we return their primary name together with:
    • counts of alternate names (aka_name)
    • counts of cast entries and distinct movies acted in
    • average order of cast entries (nr_order)
    • counts of person‑info records and distinct info types
    • share of the total distinct movies and a ranking by movie count
  The query uses CTEs to aggregate each source table before joining to the
  `name` table via the allowed join key `person_id = name.id`.
*/
WITH aka_counts AS (
    SELECT
        person_id,
        COUNT(*) AS aka_name_count,
        COUNT(DISTINCT name) AS distinct_aka_name_count
    FROM aka_name
    GROUP BY person_id
),
cast_counts AS (
    SELECT
        person_id,
        COUNT(*) AS cast_entry_count,
        COUNT(DISTINCT movie_id) AS distinct_movie_count,
        AVG(nr_order) AS avg_nr_order
    FROM cast_info
    GROUP BY person_id
),
info_counts AS (
    SELECT
        person_id,
        COUNT(*) AS info_entry_count,
        COUNT(DISTINCT info_type_id) AS distinct_info_type_count
    FROM person_info
    GROUP BY person_id
)
SELECT
    n.id AS person_id,
    n.name AS primary_name,
    n.gender,
    COALESCE(ac.aka_name_count, 0) AS aka_name_count,
    COALESCE(ac.distinct_aka_name_count, 0) AS distinct_aka_name_count,
    COALESCE(cc.cast_entry_count, 0) AS cast_entry_count,
    COALESCE(cc.distinct_movie_count, 0) AS distinct_movie_count,
    COALESCE(cc.avg_nr_order, 0) AS avg_nr_order,
    COALESCE(ic.info_entry_count, 0) AS info_entry_count,
    COALESCE(ic.distinct_info_type_count, 0) AS distinct_info_type_count,
    -- total distinct movies across all persons (window aggregate)
    SUM(COALESCE(cc.distinct_movie_count, 0)) OVER () AS total_distinct_movie_count,
    -- percentage share of distinct movies for this person
    CASE
        WHEN SUM(COALESCE(cc.distinct_movie_count, 0)) OVER () = 0 THEN 0
        ELSE COALESCE(cc.distinct_movie_count, 0) * 100.0 / SUM(COALESCE(cc.distinct_movie_count, 0)) OVER ()
    END AS movie_share_pct,
    -- ranking by number of distinct movies (most movies = rank 1)
    ROW_NUMBER() OVER (ORDER BY COALESCE(cc.distinct_movie_count, 0) DESC) AS movie_rank
FROM name n
LEFT JOIN aka_counts ac ON ac.person_id = n.id
LEFT JOIN cast_counts cc ON cc.person_id = n.id
LEFT JOIN info_counts ic ON ic.person_id = n.id
WHERE n.gender = 'M'
ORDER BY distinct_movie_count DESC, primary_name
LIMIT 100
