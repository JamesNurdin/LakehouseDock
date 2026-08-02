WITH raw AS (
  SELECT
    d.d_year AS year,
    s.s_store_id,
    s.s_state,
    w.web_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(cs.cs_net_profit) AS catalog_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS store_returns_loss,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_qty
  FROM store_sales AS ss TABLESAMPLE BERNOULLI (5)
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
  LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE
    d.d_year = 2000
    AND ib.ib_lower_bound >= 60000
    AND s.s_state = 'CA'
    AND w.web_name LIKE 'site_%'
    AND inv.inv_quantity_on_hand > 0
  GROUP BY
    d.d_year,
    s.s_store_id,
    s.s_state,
    w.web_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound
),
agg2 AS (
  SELECT
    year,
    s_state,
    ib_lower_bound,
    ib_upper_bound,
    SUM(store_sales_profit + catalog_sales_profit + web_sales_profit - store_returns_loss) AS total_profit,
    SUM(total_inventory_qty) AS total_inventory,
    COUNT(DISTINCT s_store_id) AS store_count
  FROM raw
  GROUP BY
    year,
    s_state,
    ib_lower_bound,
    ib_upper_bound
)
SELECT
  year,
  s_state,
  ib_lower_bound,
  ib_upper_bound,
  total_profit,
  total_inventory,
  store_count,
  total_profit / store_count AS avg_profit_per_store,
  ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg2
WHERE total_profit > 0
ORDER BY total_profit DESC
LIMIT 100
