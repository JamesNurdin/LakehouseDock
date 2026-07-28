WITH catalog_ret_agg AS (
    SELECT
        cr_item_sk,
        cr_returned_date_sk,
        cr_call_center_sk,
        cr_ship_mode_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2451020 AND 2451150
      AND cr_returned_time_sk BETWEEN 10000 AND 50000
    GROUP BY cr_item_sk, cr_returned_date_sk, cr_call_center_sk, cr_ship_mode_sk
)
SELECT DISTINCT
    d_sold.d_year,
    i.i_item_id,
    i.i_brand,
    s.s_store_name,
    cc.cc_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(cr_agg.total_return_amount) AS total_return_amount,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM store_sales ss
JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_ret_agg cr_agg ON cr_agg.cr_item_sk = i.i_item_sk
JOIN date_dim d_ret ON cr_agg.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                 AND ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                    AND wr.wr_item_sk = ws.ws_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand_id IN (1001001, 2004001)
  AND s.s_state = 'CA'
  AND cc.cc_division = 3
  AND sm.sm_type = 'AIR'
  AND t_sold.t_hour BETWEEN 9 AND 17
  AND wp.wp_type = 'article'
GROUP BY
    d_sold.d_year,
    i.i_item_id,
    i.i_brand,
    s.s_store_name,
    cc.cc_name
ORDER BY profit_rank
LIMIT 100
