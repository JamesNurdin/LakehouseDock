WITH intersected_cc AS (
    SELECT cc.cc_call_center_id
    FROM tpcds.call_center cc
    WHERE cc.cc_country = 'United States'
    INTERSECT
    SELECT cc.cc_call_center_id
    FROM tpcds.call_center cc
    WHERE cc.cc_employees > 500
),

distinct_depts AS (
    SELECT DISTINCT cp.cp_department
    FROM tpcds.catalog_page cp
    WHERE cp.cp_type LIKE 'A%'
),

sampled_cc AS (
    SELECT *
    FROM tpcds.call_center TABLESAMPLE BERNOULLI (10)
    WHERE cc_call_center_id IN (SELECT cc_call_center_id FROM intersected_cc)
),

agg AS (
    SELECT
        cc.cc_state,
        d_open.d_year,
        cp.cp_department,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
        SUM(cp.cp_catalog_number) AS total_catalog_number,
        MIN(cc.cc_open_date_sk) AS open_sk
    FROM sampled_cc cc
    JOIN tpcds.date_dim d_open   ON cc.cc_open_date_sk   = d_open.d_date_sk
    JOIN tpcds.date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN tpcds.catalog_page cp  ON cp.cp_start_date_sk = d_open.d_date_sk
    JOIN distinct_depts dd      ON cp.cp_department = dd.cp_department
    WHERE
        regexp_like(cp.cp_description, '(?i)store')
        AND cc.cc_name LIKE '%Center%'
        AND EXISTS (
            SELECT 1
            FROM tpcds.catalog_page cp3
            JOIN tpcds.date_dim d3 ON cp3.cp_end_date_sk = d3.d_date_sk
            WHERE d3.d_date_sk = cc.cc_closed_date_sk
              AND regexp_like(cp3.cp_description, '(?i)shop')
        )
    GROUP BY GROUPING SETS (
        (cc.cc_state, d_open.d_year, cp.cp_department),
        (cc.cc_state, d_open.d_year),
        (cp.cp_department),
        ()
    )
)
SELECT
    ag.cc_state,
    ag.d_year,
    ag.cp_department,
    ag.distinct_pages,
    ag.total_catalog_number,
    ROW_NUMBER() OVER (PARTITION BY ag.cc_state ORDER BY ag.total_catalog_number DESC) AS rn_state_total,
    (
        SELECT COUNT(*)
        FROM tpcds.catalog_page cp2
        JOIN tpcds.date_dim d2 ON cp2.cp_start_date_sk = d2.d_date_sk
        WHERE d2.d_date_sk = ag.open_sk
    ) AS pages_started_same_day
FROM agg ag
ORDER BY ag.cc_state, ag.d_year DESC, ag.cp_department
LIMIT 100
