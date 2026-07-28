WITH base AS (
   SELECT
     ws.ws_order_number,
     ws.ws_net_paid_inc_ship_tax,
     ws.ws_ext_ship_cost,
     ws.ws_quantity,
     ws.ws_bill_addr_sk,
     sd.d_year,
     sd.d_month_seq,
     sd.d_day_name,
     sd.d_moy,
     sd.d_current_day
   FROM web_sales ws
   JOIN date_dim sd
     ON ws.ws_sold_date_sk = sd.d_date_sk
   JOIN date_dim shd
     ON ws.ws_ship_date_sk = shd.d_date_sk
   WHERE sd.d_moy IN (4, 6, 8)                                 -- month filter (April, June, August)
     AND sd.d_current_day = 'N'                               -- exclude current day flag
     AND ws.ws_ext_ship_cost > 100.00                         -- only shipments costing > $100
     AND ws.ws_net_paid_inc_ship_tax BETWEEN 500.00 AND 5000.00 -- moderate ticket size
     AND ws.ws_bill_addr_sk NOT IN (115703, 5505026)          -- exclude two specific billing addresses
     AND NOT EXISTS (
           SELECT 1
           FROM web_sales ws2
           WHERE ws2.ws_bill_addr_sk = ws.ws_bill_addr_sk
             AND ws2.ws_quantity > 100                      -- anti‑join: remove customers with any large‑quantity order
         )
),
agg AS (
   SELECT
     d_year,
     d_month_seq,
     d_day_name,
     COUNT(*) AS order_cnt,
     SUM(ws_net_paid_inc_ship_tax) AS total_net_paid,
     AVG(ws_ext_ship_cost) AS avg_ship_cost,
     MIN(ws_ext_ship_cost) AS min_ship_cost,
     MAX(ws_ext_ship_cost) AS max_ship_cost
   FROM base
   GROUP BY d_year, d_month_seq, d_day_name
)
SELECT
  d_year,
  d_month_seq,
  d_day_name,
  order_cnt,
  total_net_paid,
  avg_ship_cost,
  min_ship_cost,
  max_ship_cost,
  SUM(total_net_paid) OVER (
        PARTITION BY d_year
        ORDER BY d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS cumulative_year_sales,
  RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
