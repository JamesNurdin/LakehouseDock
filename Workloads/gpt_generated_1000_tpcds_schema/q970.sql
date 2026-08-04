/* Goal: Compare call center characteristics based on open vs closed dates, categorizing tax rates, and summarizing state‑level metrics and company‑level totals while deduplicating across the two perspectives. */
WITH company_center_counts AS (
    SELECT cc_company,
           COUNT(*) AS cnt
    FROM tpcds.call_center
    GROUP BY cc_company
)
SELECT *
FROM (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        dd.d_year AS yr,
        CASE WHEN cc.cc_tax_percentage > 0.08 THEN 'High' ELSE 'Low' END AS tax_category,
        CAST((SELECT COUNT(*)
              FROM tpcds.call_center cc2
              WHERE cc2.cc_state = cc.cc_state) AS double) AS state_metric,
        cc_cnt.cnt AS company_center_cnt
    FROM tpcds.call_center cc
    FULL OUTER JOIN tpcds.date_dim dd
        ON cc.cc_open_date_sk = dd.d_date_sk
    LEFT JOIN company_center_counts cc_cnt
        ON cc.cc_company = cc_cnt.cc_company
    WHERE (dd.d_year = 2002 OR dd.d_year IS NULL)
      AND cc.cc_tax_percentage IS NOT NULL
      AND cc.cc_call_center_id IN (
          SELECT cc3.cc_call_center_id
          FROM tpcds.call_center cc3
          WHERE cc3.cc_employees > 100
      )
) AS open_view
UNION
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    dd.d_year AS yr,
    CASE WHEN cc.cc_tax_percentage = 0.00 THEN 'Zero' ELSE 'NonZero' END AS tax_category,
    CAST((SELECT AVG(cc3.cc_employees)
          FROM tpcds.call_center cc3
          WHERE cc3.cc_state = cc.cc_state) AS double) AS state_metric,
    cc_cnt.cnt AS company_center_cnt
FROM tpcds.call_center cc
FULL OUTER JOIN tpcds.date_dim dd
    ON cc.cc_closed_date_sk = dd.d_date_sk
LEFT JOIN company_center_counts cc_cnt
    ON cc.cc_company = cc_cnt.cc_company
WHERE (dd.d_year BETWEEN 2000 AND 2005 OR dd.d_year IS NULL)
  AND cc.cc_tax_percentage IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM tpcds.date_dim d2
      WHERE d2.d_date = DATE '2001-01-01'
        AND d2.d_date_sk = cc.cc_closed_date_sk
  )
ORDER BY yr DESC,
         cc_name ASC
OFFSET 0
LIMIT 100
