WITH filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2001 AND 2002
),
catalog_agg AS (
    SELECT fd.d_year AS year,
           SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN filtered_dates fd ON cr.cr_returned_date_sk = fd.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE r.r_reason_desc IN ('Damaged', 'Defective')
      AND cc.cc_state = 'CA'
    GROUP BY fd.d_year
),
web_agg AS (
    SELECT fd.d_year AS year,
           SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN filtered_dates fd ON wr.wr_returned_date_sk = fd.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE r.r_reason_desc IN ('Damaged', 'Defective')
      AND t.t_hour >= 12
    GROUP BY fd.d_year
)
SELECT ca.year,
       'Catalog' AS source,
       ca.total_return_amount
FROM catalog_agg ca
UNION ALL
SELECT wa.year,
       'Web' AS source,
       wa.total_return_amount
FROM web_agg wa
ORDER BY year, source
LIMIT 100
