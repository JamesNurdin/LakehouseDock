WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_ext_wholesale_cost,
        cs.cs_ext_list_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_profit,
        cs.cs_ship_mode_sk,
        cs.cs_quantity
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_ext_wholesale_cost > 500
      AND cs.cs_ext_list_price BETWEEN 2000 AND 10000
      AND cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_quantity >= 1
)
SELECT
    sm.sm_carrier,
    sm.sm_code,
    sm.sm_contract,
    cs.cs_sold_date_sk AS sold_date_sk,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    MAX(cr.cr_return_amount) AS max_return_amount,
    MIN(cr.cr_return_ship_cost) AS min_return_ship_cost
FROM filtered_sales cs
JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
WHERE sm.sm_carrier IN ('UPS', 'USPS')
  AND sm.sm_contract = 'P7FBIt8yd'
  AND sm.sm_type = 'AIR'
  AND cr.cr_return_ship_cost < 500
GROUP BY
    sm.sm_carrier,
    sm.sm_code,
    sm.sm_contract,
    cs.cs_sold_date_sk
ORDER BY total_sales DESC
LIMIT 100
