WITH base AS (
    SELECT
        ss.ss_sold_date_sk                AS sold_date_sk,
        td.t_hour                         AS t_hour,
        s.s_store_sk                      AS store_sk,
        s.s_store_name                    AS store_name,
        s.s_state                         AS store_state,
        c.c_customer_sk                   AS customer_sk,
        p.p_promo_id                      AS promo_id,
        ca.ca_location_type               AS location_type,
        ca.ca_zip                         AS zip_code,
        ss.ss_net_paid                    AS ss_net_paid,
        ss.ss_net_profit                  AS ss_net_profit,
        ws.ws_net_profit                  AS ws_net_profit,
        ws.ws_sales_price                 AS ws_sales_price,
        w.w_warehouse_id                  AS warehouse_id,
        wp.wp_url                         AS web_page_url,
        we.web_name                       AS web_site_name,
        inv.inv_quantity_on_hand          AS inventory_on_hand,
        r.r_reason_desc                   AS return_reason,
        sr.sr_net_loss                    AS return_net_loss
    FROM store_sales ss
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE ca.ca_location_type = 'single family'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ws.ws_net_profit > 0
)
SELECT
    store_name,
    t_hour,
    SUM(ss_net_paid)       AS total_store_sales,
    SUM(ss_net_profit)     AS total_store_profit,
    SUM(ws_net_profit)     AS total_web_profit,
    CASE WHEN SUM(ss_net_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM base
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
    WHERE sr2.sr_customer_sk = base.customer_sk
      AND r2.r_reason_desc = 'Damaged'
)
GROUP BY store_name, t_hour
ORDER BY total_store_sales DESC
LIMIT 100
