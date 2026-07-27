/*
Goal: Rank California stores for the year 2020 by their combined net profit from store sales and web sales, filtering on item price, active promotions, a specific ship‑mode contract and high‑profit stores, and flag stores with excessive return loss.
*/
WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        SUM(ss.ss_net_profit)                           AS total_store_profit,
        SUM(ws.ws_net_profit)                           AS total_web_profit,
        SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)  AS total_combined_profit,
        SUM(cr.cr_net_loss)                             AS total_return_loss
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
       AND cr.cr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_sold.d_year = 2020
      AND i.i_current_price BETWEEN 100 AND 500
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND sm.sm_contract = 'fop0bcSd91J26IVpR'
    GROUP BY s.s_store_id, s.s_store_name, d_sold.d_year
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    b.s_store_id,
    b.s_store_name,
    b.d_year,
    b.total_store_profit,
    b.total_web_profit,
    b.total_combined_profit,
    RANK() OVER (PARTITION BY b.d_year ORDER BY b.total_combined_profit DESC) AS profit_rank,
    CASE WHEN b.total_return_loss > 10000 THEN 'High Return Loss' ELSE 'OK' END AS return_loss_flag
FROM base b
ORDER BY b.total_combined_profit DESC
LIMIT 100
