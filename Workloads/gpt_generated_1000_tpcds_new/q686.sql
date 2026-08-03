WITH max_1999_net AS (
    SELECT max(cs2.cs_net_paid_inc_ship_tax) AS max_val
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 1999
)
SELECT year,
       source,
       metric_amount
FROM (
    SELECT
        d.d_year AS year,
        'sales' AS source,
        SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_paid_inc_ship_tax ELSE 0 END) AS metric_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
      AND cp.cp_department = 'Electronics'
      AND cs.cs_net_paid_inc_ship_tax > (SELECT max_val FROM max_1999_net)
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = cs.cs_order_number
            AND wr.wr_returned_date_sk = cs.cs_sold_date_sk
      )
    GROUP BY d.d_year
    UNION
    SELECT
        d.d_year AS year,
        'returns' AS source,
        SUM(wr.wr_return_amt) AS metric_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2000
      AND wp.wp_type = 'product'
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_order_number = wr.wr_order_number
            AND cs2.cs_sold_date_sk = wr.wr_returned_date_sk
      )
    GROUP BY d.d_year
) AS combined
ORDER BY year, source
LIMIT 100
