WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
)
SELECT
    d_sold.d_year                                   AS sold_year,
    sm.sm_carrier,
    w.w_warehouse_name,
    COUNT(DISTINCT sa.cs_order_number)             AS orders,
    SUM(sa.cs_net_paid)                             AS total_paid,
    SUM(sa.cs_net_profit)                           AS total_profit,
    AVG(sa.cs_net_paid)                             AS avg_paid,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_mode_sk = sm.sm_ship_mode_sk
    )                                              AS avg_profit_by_mode
FROM sales_agg sa
-- sold date dimension
JOIN date_dim d_sold ON sa.cs_sold_date_sk = d_sold.d_date_sk
-- ship date dimension
JOIN date_dim d_ship ON sa.cs_ship_date_sk = d_ship.d_date_sk
-- time dimension for the sale time
JOIN time_dim td ON sa.cs_sold_time_sk = td.t_time_sk
-- ship mode
JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
-- warehouse
JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
-- billing customer
JOIN customer c_bill ON sa.cs_bill_customer_sk = c_bill.c_customer_sk
-- billing customer demographics
JOIN customer_demographics cd_bill ON sa.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
-- first sales date of the billing customer (reuse date_dim)
JOIN date_dim d_cust_first_sales ON c_bill.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
-- web page visited by the billing customer
JOIN web_page wp ON wp.wp_customer_sk = c_bill.c_customer_sk
-- web site associated via the web page creation date (reuse date_dim as a bridge)
JOIN date_dim d_ws_open ON wp.wp_creation_date_sk = d_ws_open.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_ws_open.d_date_sk
-- anti‑join: exclude rows where the ship mode carrier is MSC (using NOT EXISTS)
WHERE NOT EXISTS (
    SELECT 1
    FROM ship_mode sm2
    WHERE sm2.sm_ship_mode_sk = sm.sm_ship_mode_sk
      AND sm2.sm_carrier = 'MSC'
)
GROUP BY
    d_sold.d_year,
    sm.sm_carrier,
    w.w_warehouse_name,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_mode_sk = sm.sm_ship_mode_sk
    )
HAVING SUM(sa.cs_net_paid) > 10000
ORDER BY total_paid DESC
LIMIT 100
