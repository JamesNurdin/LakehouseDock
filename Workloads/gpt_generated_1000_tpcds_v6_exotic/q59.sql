WITH joined_data AS (
   SELECT
     s.s_store_id,
     s.s_state,
     i.i_category,
     i.i_brand,
     ib.ib_upper_bound,
     w.w_city,
     sm.sm_type,
     td.t_hour,
     ss.ss_ext_sales_price,
     ss.ss_net_profit,
     cr.cr_return_amount,
     cr.cr_net_loss,
     ws.ws_ext_sales_price AS web_sales_price,
     ws.ws_net_profit   AS web_net_profit,
     wr.wr_return_amt,
     wr.wr_net_loss,
     wp.wp_max_ad_count,
     CASE WHEN ss.ss_net_profit > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag
   FROM store_sales ss
   JOIN time_dim td
     ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN catalog_returns cr
     ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_time_sk = td.t_time_sk
   LEFT JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_time_sk = td.t_time_sk
   LEFT JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_time_sk = td.t_time_sk
    AND wr.wr_order_number = ws.ws_order_number
   LEFT JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_site we
     ON ws.ws_web_site_sk = we.web_site_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND i.i_category = 'Electronics'
     AND w.w_city IN ('Shiloh', 'Greenwood')
     AND ib.ib_upper_bound <= 50000
     AND wp.wp_max_ad_count >= 2
     AND s.s_state = 'CA'
),
store_category_agg AS (
   SELECT
     s_store_id,
     i_category,
     SUM(ss_ext_sales_price)               AS total_sales,
     SUM(ss_net_profit)                    AS total_profit,
     COUNT(*)                               AS transaction_cnt,
     SUM(CASE WHEN profit_flag = 'HIGH' THEN 1 ELSE 0 END) AS high_profit_cnt
   FROM joined_data
   GROUP BY s_store_id, i_category
   HAVING SUM(ss_ext_sales_price) > 10000
)
SELECT
  s_store_id,
  i_category,
  total_sales,
  total_profit,
  transaction_cnt,
  high_profit_cnt,
  CAST(high_profit_cnt AS double) / transaction_cnt AS high_profit_ratio
FROM store_category_agg
WHERE s_store_id IN (
    SELECT s_store_id
    FROM store
    WHERE s_market_id IN (
        SELECT s_market_id
        FROM store
        WHERE s_state = 'CA'
    )
)
ORDER BY total_sales DESC
LIMIT 100
