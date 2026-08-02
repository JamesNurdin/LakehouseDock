WITH base_sales AS (
   SELECT
       ws.ws_order_number,
       ws.ws_ship_date_sk,
       ws.ws_ext_ship_cost,
       ws.ws_net_paid_inc_tax,
       d_sold.d_year,
       CASE WHEN ws.ws_ext_ship_cost > 2000 THEN 'High' ELSE 'Low' END AS ship_cost_category,
       CASE WHEN d_ship.d_date IS NULL THEN 'NoShipDate' ELSE 'HasShipDate' END AS shipping_status
   FROM web_sales ws
   INNER JOIN date_dim d_sold
       ON ws.ws_sold_date_sk = d_sold.d_date_sk
   LEFT JOIN date_dim d_ship
       ON ws.ws_ship_date_sk = d_ship.d_date_sk
   INNER JOIN customer_address ca_bill
       ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN customer_address ca_ship
       ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   WHERE d_sold.d_fy_year = 1902
     AND d_sold.d_dom IN (5, 8, 15, 20)
     AND ca_bill.ca_gmt_offset = -5.00
     AND ws.ws_ext_ship_cost > 1000
     AND d_sold.d_date >= DATE '1998-01-01'
),

sold_sales AS (
   SELECT
       ws_order_number,
       d_year,
       ws_ext_ship_cost,
       ws_net_paid_inc_tax,
       ship_cost_category,
       shipping_status,
       ws_ship_date_sk
   FROM base_sales
   WHERE ws_ship_date_sk IS NOT NULL
),

unshipped_sales AS (
   SELECT
       ws_order_number,
       d_year,
       ws_ext_ship_cost,
       ws_net_paid_inc_tax,
       ship_cost_category,
       shipping_status,
       ws_ship_date_sk
   FROM base_sales
   WHERE ws_ship_date_sk IS NULL
),

combined AS (
   SELECT
       ws_order_number,
       d_year,
       ws_ext_ship_cost,
       ws_net_paid_inc_tax,
       ship_cost_category,
       shipping_status,
       ws_ship_date_sk
   FROM sold_sales
   UNION ALL
   SELECT
       ws_order_number,
       d_year,
       ws_ext_ship_cost,
       ws_net_paid_inc_tax,
       ship_cost_category,
       shipping_status,
       ws_ship_date_sk
   FROM unshipped_sales
),

agg AS (
   SELECT
       d_year,
       ship_cost_category,
       shipping_status,
       COUNT(*) AS order_cnt,
       SUM(ws_net_paid_inc_tax) AS total_net_paid,
       AVG(ws_ext_ship_cost) AS avg_ship_cost,
       MIN(ws_ext_ship_cost) AS min_ship_cost,
       MAX(ws_ext_ship_cost) AS max_ship_cost
   FROM combined
   GROUP BY d_year, ship_cost_category, shipping_status
)
SELECT
   d_year,
   ship_cost_category,
   shipping_status,
   order_cnt,
   total_net_paid,
   avg_ship_cost,
   min_ship_cost,
   max_ship_cost,
   ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rank_by_year
FROM agg
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 100
