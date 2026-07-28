WITH sales_agg AS (
  SELECT
    s.s_store_id,
    i.i_item_id,
    p.p_promo_id,
    d.d_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN catalog_returns cr ON ss.ss_item_sk = cr.cr_item_sk
  LEFT JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
                      AND d.d_date_sk = inv.inv_date_sk
                      AND w.w_warehouse_sk = inv.inv_warehouse_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'TX'
    AND i.i_brand = 'Brand#23'
    AND p.p_discount_active = 'Y'
  GROUP BY s.s_store_id, i.i_item_id, p.p_promo_id, d.d_year
)

SELECT
  s_store_id,
  i_item_id,
  p_promo_id,
  d_year,
  total_sales,
  total_profit,
  sales_cnt,
  total_sales / NULLIF(sales_cnt, 0) AS avg_sale_per_txn
FROM sales_agg
WHERE total_sales > 10000
ORDER BY total_sales DESC
LIMIT 100
