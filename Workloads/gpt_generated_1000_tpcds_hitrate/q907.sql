/*
  Goal: Identify the top 5 catalog departments for each call center (in California) based on total return amount
  for the 2022 Q2 period, highlighting high‑value return quantities, the department's share of the year's
  total returns, and the change from the previous department within the same call center.
*/
WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022                                   -- filter 1
      AND d.d_quarter_name = '1904Q2'                       -- filter 2
      AND cr.cr_return_amount > 1000                       -- filter 3
),
agg_by_center_dept AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        cp.cp_department,
        SUM(fr.cr_return_amount) AS total_return_amount,
        AVG(fr.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS return_count,
        MIN(fr.cr_return_amount) AS min_return_amount,
        MAX(fr.cr_return_amount) AS max_return_amount,
        -- CASE expression inside aggregation
        SUM(CASE WHEN fr.cr_return_amount > 5000 THEN fr.cr_return_quantity ELSE 0 END) AS high_value_qty,
        -- scalar subquery returning the year‑wide total return amount
        (SELECT SUM(cr2.cr_return_amount)
         FROM catalog_returns cr2
         JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2022) AS year_total_return_amount
    FROM filtered_returns fr
    JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk               -- join rule
    JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk               -- join rule
    JOIN customer cust ON fr.cr_refunded_customer_sk = cust.c_customer_sk               -- join rule
    JOIN customer_demographics cd ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk           -- join rule
    WHERE cp.cp_type = 'monthly'                         -- filter 4
      AND cc.cc_state = 'CA'                              -- filter 5
      AND cd.cd_gender = 'M'                              -- filter 6
      AND cc.cc_gmt_offset > 0                           -- filter 7
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_state,
        cp.cp_department
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_return_amount DESC) AS rnk,
        LAG(total_return_amount) OVER (PARTITION BY cc_call_center_id ORDER BY total_return_amount DESC) AS prev_total_return_amount
    FROM agg_by_center_dept
)
SELECT
    cc_call_center_id,
    cc_state,
    cp_department,
    total_return_amount,
    avg_return_amount,
    return_count,
    min_return_amount,
    max_return_amount,
    high_value_qty,
    year_total_return_amount,
    prev_total_return_amount,
    CASE
        WHEN total_return_amount > year_total_return_amount * 0.05 THEN 'Top5Pct'
        ELSE 'Other'
    END AS contribution_bucket
FROM ranked
WHERE rnk <= 5                               -- top‑k per call center
ORDER BY total_return_amount DESC
LIMIT 100
