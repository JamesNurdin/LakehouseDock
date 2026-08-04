WITH base_join AS (
  SELECT
    d.d_year,
    cs.cs_net_profit,
    ss.ss_net_profit,
    ws.web_site_id
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
  JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN reason r_cs ON cr.cr_reason_sk = r_cs.r_reason_sk
  JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
),
sub_catalog AS (
  SELECT
    d_year,
    SUM(cs_net_profit) AS profit,
    'catalog' AS src
  FROM base_join
  GROUP BY d_year
),
sub_store AS (
  SELECT
    d_year,
    SUM(ss_net_profit) AS profit,
    'store' AS src
  FROM base_join
  GROUP BY d_year
),
intersect_years AS (
  SELECT d_year FROM sub_catalog
  INTERSECT
  SELECT d_year FROM sub_store
),
union_profits AS (
  SELECT d_year, profit FROM sub_catalog
  UNION
  SELECT d_year, profit FROM sub_store
)
SELECT
  u.d_year,
  SUM(u.profit) AS total_profit
FROM union_profits u
JOIN intersect_years iy ON u.d_year = iy.d_year
GROUP BY u.d_year
ORDER BY total_profit DESC
LIMIT 100
