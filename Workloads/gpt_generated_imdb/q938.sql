WITH title_kind AS (
    SELECT
        t.id,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
),
cast_per_title AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id
    GROUP BY ci.movie_id
),
company_per_title AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    GROUP BY mc.movie_id
),
keyword_per_title AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN title t
        ON mk.movie_id = t.id
    GROUP BY mk.movie_id
)
SELECT
    tk.kind,
    COUNT(DISTINCT tk.id) AS total_titles,
    AVG(tk.production_year) AS avg_production_year,
    AVG(COALESCE(cp.cast_member_count, 0)) AS avg_cast_members_per_title,
    AVG(COALESCE(cmp.company_count, 0)) AS avg_companies_per_title,
    AVG(COALESCE(kp.keyword_count, 0)) AS avg_keywords_per_title
FROM title_kind tk
LEFT JOIN cast_per_title cp
    ON tk.id = cp.movie_id
LEFT JOIN company_per_title cmp
    ON tk.id = cmp.movie_id
LEFT JOIN keyword_per_title kp
    ON tk.id = kp.movie_id
GROUP BY tk.kind
ORDER BY total_titles DESC
