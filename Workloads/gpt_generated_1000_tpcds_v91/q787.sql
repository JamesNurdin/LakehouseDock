WITH joined_data AS (
    SELECT
        i.i_category AS i_category,
        i.i_class AS i_class,
        s.s_store_name AS store_name,
        ss.ss_net_profit AS ss_profit,
        ws.ws_net_profit AS ws_profit,
        cc.cc_name AS call_center_name,
        r.r_reason_desc AS reason_desc,
        p_ws.p_promo_name AS promo_name,
        d_ss.d_year AS year,
        ca_ss.ca_city AS store_address_city,
        wsite.web_name AS web_site_name
    FROM store_sales AS ss TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d_ss
      ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss
      ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p_ss
      ON ss.ss_promo_sk = p_ss.p_promo_sk
     AND p_ss.p_item_sk = i.i_item_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca_ss
      ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_cr
      ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr
      ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws
      ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws
      ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN date_dim d_ws_ship
      ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p_ws
      ON ws.ws_promo_sk = p_ws.p_promo_sk
     AND p_ws.p_item_sk = i.i_item_sk
    JOIN customer_address ca_ws_bill
      ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_address ca_ws_ship
      ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN date_dim d_store_closed
      ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_closed
      ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
      ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cp_start
      ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
      ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_p_start
      ON p_ws.p_start_date_sk = d_p_start.d_date_sk
    JOIN date_dim d_p_end
      ON p_ws.p_end_date_sk = d_p_end.d_date_sk
    JOIN date_dim d_web_open
      ON wsite.web_open_date_sk = d_web_open.d_date_sk
    JOIN date_dim d_web_close
      ON wsite.web_close_date_sk = d_web_close.d_date_sk
    WHERE d_ss.d_year = 2001
      AND i.i_category = 'sports-apparel'
      AND p_ws.p_discount_active = 'Y'
      AND s.s_tax_percentage > 5.0
)
SELECT
    i_category,
    i_class,
    COUNT(*) AS transaction_cnt,
    SUM(ss_profit) AS total_store_profit,
    SUM(ws_profit) AS total_web_profit,
    SUM(ss_profit + ws_profit) AS total_combined_profit,
    AVG(ss_profit + ws_profit) AS avg_combined_profit_per_txn
FROM joined_data
GROUP BY i_category, i_class
HAVING SUM(ss_profit + ws_profit) > 100000
ORDER BY total_combined_profit DESC
LIMIT 100
