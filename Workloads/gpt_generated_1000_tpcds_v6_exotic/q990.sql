SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    i.i_category,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_store_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    CASE
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_desc,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank_state
FROM web_sales ws
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
-- Web returns linked to the sale
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
-- Store returns linked through the shared item
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE d_ws.d_year = 2001
  AND i.i_current_price BETWEEN 10 AND 100
  AND cd.cd_purchase_estimate >= 5000
  AND hd.hd_dep_count <= 5
  AND ib.ib_upper_bound > 50000
  AND sm.sm_type = 'AIR'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    i.i_category,
    cd.cd_gender
ORDER BY total_web_profit DESC
LIMIT 100
