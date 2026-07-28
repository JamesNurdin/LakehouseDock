WITH ss AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_promo_sk,
        ss_addr_sk,
        SUM(ss_net_profit) AS store_profit,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk, ss_sold_time_sk, ss_item_sk, ss_promo_sk, ss_addr_sk
),
ws AS (
    SELECT
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_item_sk,
        ws_promo_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_web_page_sk,
        ws_bill_addr_sk,
        SUM(ws_net_profit) AS web_profit,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_sold_time_sk, ws_item_sk, ws_promo_sk, ws_ship_mode_sk, ws_warehouse_sk, ws_web_page_sk, ws_bill_addr_sk
)
SELECT
    d.d_year,
    s.s_store_name,
    i.i_category,
    p.p_promo_name,
    SUM(COALESCE(ss.store_profit, 0) + COALESCE(ws.web_profit, 0)) AS total_profit,
    SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity
FROM ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm_ret
  ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ws
  ON ws.ws_sold_date_sk = d.d_date_sk
  AND ws.ws_item_sk = i.i_item_sk
  AND ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
WHERE
    d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND r.r_reason_desc LIKE '%model%'
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY GROUPING SETS (
    (d.d_year, s.s_store_name, i.i_category, p.p_promo_name),
    (d.d_year, s.s_store_name, i.i_category),
    (d.d_year, s.s_store_name),
    (d.d_year),
    ()
)
ORDER BY total_profit DESC
LIMIT 100
