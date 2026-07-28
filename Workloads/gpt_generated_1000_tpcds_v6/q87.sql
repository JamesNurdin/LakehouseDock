WITH filtered AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        d1.d_year,
        d1.d_fy_year,
        d1.d_qoy,
        d1.d_date,
        sm.sm_ship_mode_sk,
        sm.sm_code,
        CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_type,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        d2.d_year AS return_year,
        ROW_NUMBER() OVER (PARTITION BY d1.d_year ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                             AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d1.d_date_sk
    WHERE d1.d_fy_year = 1911
      AND d1.d_qoy = 2
      AND sm.sm_code IN ('AIR', 'SEA')
      AND cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
      AND cr.cr_return_quantity = 0
      AND d1.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND NOT EXISTS (
          SELECT 1 FROM store_sales ss2
          WHERE ss2.ss_sold_date_sk = cs.cs_sold_date_sk
            AND ss2.ss_item_sk = cs.cs_item_sk
      )
)
SELECT
    cs_sold_date_sk,
    cs_order_number,
    cs_item_sk,
    d_year,
    ship_type,
    profit_rank,
    cs_ext_sales_price,
    cr_return_amount
FROM filtered
WHERE profit_rank <= 10
ORDER BY d_year, profit_rank
LIMIT 100
