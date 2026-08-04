WITH intersect_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2000
      AND cs.cs_quantity > 5
    INTERSECT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2000
      AND cr.cr_return_quantity > 0
)
SELECT
    d.d_year,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_promo_name,
    s.s_store_name,
    ws.web_name,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    AVG(cs.cs_net_profit) AS avg_profit,
    MIN(cs.cs_ext_sales_price) AS min_sale,
    MAX(cs.cs_ext_sales_price) AS max_sale
FROM intersect_orders io
JOIN catalog_sales cs
  ON io.cs_order_number = cs.cs_order_number
JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
FULL OUTER JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
FULL OUTER JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE w.w_country = 'United States'
  AND p.p_promo_name = 'Unknown'
  AND sm.sm_type = 'AIR'
GROUP BY d.d_year,
         sm.sm_type,
         w.w_warehouse_name,
         p.p_promo_name,
         s.s_store_name,
         ws.web_name
ORDER BY total_sales DESC
LIMIT 100
