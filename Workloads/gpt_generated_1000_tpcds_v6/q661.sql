WITH profit_per_customer AS (
  SELECT
    c.c_customer_id,
    d.d_year,
    i_cs.i_category,
    COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
  JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
  JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
  JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
  WHERE d.d_year = 2001
    AND i_cs.i_category = 'Sports'
    AND hd.hd_vehicle_count >= 1
    AND cc.cc_state = 'CA'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_quantity > 0
    )
  GROUP BY c.c_customer_id, d.d_year, i_cs.i_category
)
SELECT
  cpc.c_customer_id,
  cpc.d_year,
  cpc.i_category,
  cpc.total_net_profit,
  AVG(cpc.total_net_profit) OVER (PARTITION BY cpc.i_category) AS avg_category_profit,
  ROW_NUMBER() OVER (PARTITION BY cpc.i_category ORDER BY cpc.total_net_profit DESC) AS category_rank
FROM profit_per_customer cpc
WHERE cpc.total_net_profit > 0
ORDER BY cpc.total_net_profit DESC
LIMIT 100
