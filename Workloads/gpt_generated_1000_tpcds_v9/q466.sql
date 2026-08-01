WITH base_agg AS (
  SELECT
    s.s_store_id,
    d.d_year AS sales_year,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_discount_amt ELSE 0 END) AS promo_discount_amount,
    SUM(ss.ss_ext_discount_amt) AS store_total_discount,
    SUM(ws.ws_ext_discount_amt) AS web_total_discount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS returns_loss,
    SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(COALESCE(wr.wr_net_loss, 0)) AS total_gross_sales,
    (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) AS total_net_profit,
    CASE WHEN (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk AND cc.cc_division_name = 'able'
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                     AND ws.ws_sold_date_sk = d.d_date_sk
                     AND ws.ws_sold_time_sk = t.t_time_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                            AND wr.wr_item_sk = i.i_item_sk
                            AND wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
                       AND r.r_reason_desc LIKE '%warranty%'
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_warehouse_sk = wh.w_warehouse_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND s.s_state = 'CA'
    AND i.i_category = 'Electronics'
    AND sm.sm_code = 'AIR'
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY s.s_store_id, d.d_year
)
SELECT
  sales_year,
  COUNT(*) AS num_stores,
  AVG(total_net_profit) AS avg_total_net_profit,
  SUM(total_gross_sales) AS sum_gross_sales
FROM base_agg
GROUP BY sales_year
HAVING AVG(total_net_profit) > 50000
ORDER BY avg_total_net_profit DESC
LIMIT 100
