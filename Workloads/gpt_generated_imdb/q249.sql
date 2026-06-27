WITH cast_details AS (
    SELECT
        ci.movie_id,
        n.id AS person_id,
        n.gender,
        cn.id AS char_id,
        cn.name AS character_name
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    LEFT JOIN char_name cn ON CAST(ci.person_role_id AS integer) = cn.id
),
person_alts AS (
    SELECT
        an.person_id,
        COUNT(*) AS alt_name_count
    FROM aka_name an
    GROUP BY an.person_id
),
movie_info_counts AS (
    SELECT
        mi.movie_id,
        COUNT(*) FILTER (WHERE it.info = 'plot') AS plot_info_cnt,
        COUNT(*) FILTER (WHERE it.info = 'trivia') AS trivia_info_cnt
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT
    t.id AS movie_id,
    t.title,
    kt.kind,
    t.production_year,
    COUNT(DISTINCT cd.person_id) AS cast_member_count,
    COUNT(DISTINCT cd.char_id) AS character_count,
    SUM(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_cast,
    SUM(CASE WHEN cd.gender = 'F' THEN 1 ELSE 0 END) AS female_cast,
    COALESCE(SUM(pa.alt_name_count), 0) AS total_alternate_names,
    COALESCE(mic.plot_info_cnt, 0) AS plot_info_count,
    COALESCE(mic.trivia_info_cnt, 0) AS trivia_info_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_details cd ON cd.movie_id = t.id
LEFT JOIN person_alts pa ON pa.person_id = cd.person_id
LEFT JOIN movie_info_counts mic ON mic.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY t.id, t.title, kt.kind, t.production_year, mic.plot_info_cnt, mic.trivia_info_cnt
ORDER BY t.production_year DESC, cast_member_count DESC
LIMIT 10
