WITH ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_web_page_sk,
        ws.ws_ship_mode_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
)
SELECT
    d_ret.d_date AS return_date,
    s.s_store_name,
    i.i_product_name,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COALESCE(SUM(ws_base.ws_net_profit), 0) AS total_web_profit,
    CASE
        WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High Loss'
        WHEN SUM(sr.sr_net_loss) BETWEEN 100 AND 1000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    CASE WHEN COALESCE(SUM(ws_base.ws_quantity), 0) > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_category,
    RANK() OVER (PARTITION BY d_ret.d_year ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank_by_year,
    (SELECT MAX(ib.ib_upper_bound) FROM income_band ib) AS max_income_upper_bound
FROM store_returns sr
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d_ret.d_date_sk
LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
LEFT JOIN ws_base ws_base
    ON ws_base.ws_sold_date_sk = d_ret.d_date_sk
   AND ws_base.ws_item_sk = i.i_item_sk
LEFT JOIN web_page wp ON ws_base.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN ship_mode sm ON ws_base.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d_ret.d_year = 2001
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND (sm.sm_type = 'AIR' OR sm.sm_type IS NULL)
  AND (cp.cp_type = 'PROMO' OR cp.cp_type IS NULL)
  AND (cc.cc_market_manager = 'Mike' OR cc.cc_market_manager IS NULL)
GROUP BY
    d_ret.d_date,
    d_ret.d_year,
    s.s_store_name,
    i.i_product_name
ORDER BY total_return_loss DESC
LIMIT 100
