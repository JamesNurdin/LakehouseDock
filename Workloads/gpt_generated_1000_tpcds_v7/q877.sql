WITH joined AS (
  SELECT
    d.d_year,
    p.p_promo_name,
    ws.ws_order_number,
    ss.ss_quantity,
    ss.ss_net_profit,
    cs.cs_net_profit,
    ws.ws_net_profit,
    wr.wr_return_amt_inc_tax,
    inv.inv_quantity_on_hand,
    web_site.web_state,
    p.p_discount_active
  FROM tpcds.date_dim d
  JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN tpcds.customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN tpcds.web_site web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
),
aggregated AS (
  SELECT
    d_year,
    p_promo_name,
    ws_order_number,
    inv_quantity_on_hand,
    web_state,
    SUM(ss_net_profit + cs_net_profit + ws_net_profit - wr_return_amt_inc_tax) AS total_profit
  FROM joined
  WHERE d_year = 2001
    AND ss_quantity > 5
    AND p_discount_active = 'Y'
    AND inv_quantity_on_hand > 500
    AND web_state = 'CA'
    AND wr_return_amt_inc_tax > 500
  GROUP BY
    d_year,
    p_promo_name,
    ws_order_number,
    inv_quantity_on_hand,
    web_state
)
SELECT
  d_year,
  p_promo_name,
  ws_order_number,
  inv_quantity_on_hand,
  web_state,
  total_profit,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
  CASE WHEN inv_quantity_on_hand > 800 THEN 'High Stock' ELSE 'Normal Stock' END AS stock_level
FROM aggregated
ORDER BY total_profit DESC
LIMIT 20
