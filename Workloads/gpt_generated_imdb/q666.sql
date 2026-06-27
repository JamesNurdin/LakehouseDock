WITH title_stats AS (
    SELECT
        kt.kind AS kind,
        COUNT(DISTINCT t.id) AS total_titles,
        AVG(t.production_year) AS avg_production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY kt.kind
),
cast_counts AS (
    SELECT
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_members
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY kt.kind
),
company_counts AS (
    SELECT
        kt.kind AS kind,
        COUNT(DISTINCT mc.company_id) AS distinct_companies
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY kt.kind
),
keyword_counts AS (
    SELECT
        kt.kind AS kind,
        COUNT(DISTINCT k.keyword) AS distinct_keywords
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY kt.kind
),
keyword_freq AS (
    SELECT
        kt.kind AS kind,
        k.keyword AS keyword,
        COUNT(*) AS kw_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY kt.kind, k.keyword
),
top_keywords AS (
    SELECT
        kind,
        array_join(
            slice(array_agg(keyword ORDER BY kw_cnt DESC), 1, 3),
            ', '
        ) AS top_keywords
    FROM keyword_freq
    GROUP BY kind
)
SELECT
    ts.kind,
    ts.total_titles,
    ts.avg_production_year,
    cc.distinct_cast_members,
    comc.distinct_companies,
    kc.distinct_keywords,
    tk.top_keywords
FROM title_stats ts
LEFT JOIN cast_counts cc       ON ts.kind = cc.kind
LEFT JOIN company_counts comc ON ts.kind = comc.kind
LEFT JOIN keyword_counts kc   ON ts.kind = kc.kind
LEFT JOIN top_keywords tk     ON ts.kind = tk.kind
ORDER BY ts.total_titles DESC
