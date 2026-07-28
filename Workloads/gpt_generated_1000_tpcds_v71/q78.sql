WITH base AS (
    SELECT
        ws.web_city,
        cc.cc_division_name,
        d_ret.d_year,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        MIN(wr.wr_return_amt) AS min_return_amount,
        MAX(wr.wr_return_amt) AS max_return_amount
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND ws.web_city = 'Spring Hill'
      AND cc.cc_division_name = 'Technology'
      AND cp.cp_type = 'C'
      AND wr.wr_return_ship_cost > 100.00
      AND EXISTS (
          SELECT 1 FROM catalog_page cp2
          WHERE cp2.cp_catalog_page_id = cp.cp_catalog_page_id
            AND cp2.cp_catalog_number BETWEEN 100 AND 200
      )
    GROUP BY ws.web_city, cc.cc_division_name, d_ret.d_year
)
SELECT
    web_city,
    cc_division_name,
    d_year,
    num_returns,
    total_return_amount,
    avg_return_quantity,
    min_return_amount,
    max_return_amount,
    RANK() OVER (PARTITION BY web_city ORDER BY total_return_amount DESC) AS city_return_rank,
    SUM(total_return_amount) OVER (PARTITION BY cc_division_name) AS division_total_return_amount
FROM base
ORDER BY total_return_amount DESC
LIMIT 100
