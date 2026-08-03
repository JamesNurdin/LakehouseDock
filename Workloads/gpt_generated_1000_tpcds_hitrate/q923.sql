WITH base AS (
  SELECT
    cc.cc_call_center_sk,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    ss.ss_ticket_number,
    s.s_store_sk,
    s.s_store_name,
    sr.sr_store_sk,
    r.r_reason_desc,
    wr.wr_return_quantity,
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_sold_date_sk,
    w.w_warehouse_sk,
    i.inv_quantity_on_hand,
    d.d_year,
    d.d_date
  FROM call_center cc
  JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_returns wr
    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d
    ON i.inv_date_sk = d.d_date_sk
  WHERE cc.cc_country = 'United States'
    AND td.t_shift = 'first'
    AND d.d_year = 2001
)
SELECT
  base.d_year,
  base.s_store_name,
  COUNT(DISTINCT demo.c_customer_sk) AS unique_customers,
  SUM(base.ws_net_paid) AS total_net_paid,
  AVG(base.ws_net_paid) AS avg_net_paid,
  MIN(base.ws_net_paid) AS min_net_paid,
  MAX(base.ws_net_paid) AS max_net_paid,
  SUM(base.inv_quantity_on_hand) AS total_inventory,
  base.r_reason_desc,
  demo.cd_demo_sk,
  demo.hd_demo_sk
FROM base
LEFT JOIN LATERAL (
   SELECT cd.cd_demo_sk, hd.hd_demo_sk, c.c_customer_sk
   FROM customer_demographics cd
   JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   WHERE cd.cd_purchase_estimate > 8000
   LIMIT 1
) AS demo ON TRUE
JOIN (
   SELECT MAX(d_date_sk) AS max_date_sk FROM date_dim WHERE d_year = 2001
) AS max_date ON base.cs_sold_date_sk = max_date.max_date_sk
GROUP BY
  base.d_year,
  base.s_store_name,
  base.r_reason_desc,
  demo.cd_demo_sk,
  demo.hd_demo_sk
ORDER BY total_net_paid DESC
LIMIT 100
