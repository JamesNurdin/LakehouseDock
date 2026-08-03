WITH ws_ranked AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_net_profit,
        ws.ws_ext_list_price,
        ws.ws_quantity,
        ws.ws_bill_customer_sk,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        t_ws.t_hour,
        c_bill.c_first_name,
        c_bill.c_last_name,
        ca_bill.ca_city,
        wp.wp_url,
        wep.web_site_id,
        wep.web_name,
        ROW_NUMBER() OVER (PARTITION BY wep.web_site_id ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    JOIN time_dim t_ws
      ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN customer c_bill
      ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
      ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wep
      ON ws.ws_web_site_sk = wep.web_site_sk
    WHERE t_ws.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_list_price > 2000
      AND ca_bill.ca_country = 'United States'
      AND wep.web_state = 'CA'
)
SELECT
    ws_ranked.ws_order_number,
    ws_ranked.ws_sold_date_sk,
    ws_ranked.ws_net_profit,
    CASE
        WHEN ws_ranked.ws_net_profit >= 1000 THEN 'HIGH'
        WHEN ws_ranked.ws_net_profit >= 0    THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ws_ranked.t_hour,
    ws_ranked.c_first_name,
    ws_ranked.c_last_name,
    ws_ranked.ca_city,
    ws_ranked.wp_url,
    ws_ranked.web_name,
    ws_ranked.rn
FROM ws_ranked
JOIN store_sales ss
    ON ss.ss_sold_time_sk = ws_ranked.ws_sold_time_sk
JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer c_store
    ON ss.ss_customer_sk = c_store.c_customer_sk
JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = t_ss.t_time_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
WHERE c_store.c_birth_year BETWEEN 1960 AND 1990
  AND ca_store.ca_state = 'TX'
  AND r.r_reason_desc LIKE '%defect%'
  AND ss.ss_net_profit > 0
  AND ws_ranked.rn <= 3
ORDER BY ws_ranked.web_name, ws_ranked.rn
LIMIT 100
