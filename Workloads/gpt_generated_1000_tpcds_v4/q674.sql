/* goal: Identify top‑performing store‑brand‑category combinations by net paid amount, showing store status and sales channel, while ensuring the customer had at least one catalog sale on the same calendar date */
WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
)
SELECT
    d.d_year,
    s.s_store_name,
    i.i_brand,
    i.i_category,
    c.c_customer_id,
    hd.hd_buy_potential,
    COUNT(DISTINCT ss.ss_ticket_number)                         AS orders,
    SUM(ss.ss_net_paid)                                         AS total_net_paid,
    SUM(ss.ss_net_profit)                                       AS total_net_profit,
    CASE WHEN s.s_closed_date_sk IS NULL THEN 'Open' ELSE 'Closed' END AS store_status,
    CASE WHEN cs.cs_quantity > 0 THEN 'Catalog' ELSE 'Store' END          AS sales_channel
FROM base_sales ss
JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i                    ON ss.ss_item_sk      = i.i_item_sk
JOIN customer c                ON ss.ss_customer_sk  = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk     = hd.hd_demo_sk
JOIN customer_address ca       ON ss.ss_addr_sk      = ca.ca_address_sk
JOIN store s                   ON ss.ss_store_sk     = s.s_store_sk
JOIN promotion p               ON ss.ss_promo_sk     = p.p_promo_sk
LEFT JOIN store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r_sr          ON sr.sr_reason_sk      = r_sr.r_reason_sk
LEFT JOIN web_sales ws        
       ON ws.ws_bill_customer_sk = ss.ss_customer_sk
      AND ws.ws_sold_date_sk      = ss.ss_sold_date_sk
LEFT JOIN ship_mode sm_ws      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN web_returns wr       
       ON wr.wr_order_number   = ws.ws_order_number
LEFT JOIN reason r_wr          ON wr.wr_reason_sk      = r_wr.r_reason_sk
LEFT JOIN catalog_sales cs    
       ON cs.cs_bill_customer_sk = ss.ss_customer_sk
      AND cs.cs_sold_date_sk      = ss.ss_sold_date_sk
LEFT JOIN ship_mode sm_cs      ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
LEFT JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN promotion p2         ON cs.cs_promo_sk      = p2.p_promo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE cs2.cs_bill_customer_sk = ss.ss_customer_sk
      AND d2.d_date = d.d_date
)
GROUP BY
    d.d_year,
    s.s_store_name,
    i.i_brand,
    i.i_category,
    c.c_customer_id,
    hd.hd_buy_potential,
    CASE WHEN s.s_closed_date_sk IS NULL THEN 'Open' ELSE 'Closed' END,
    CASE WHEN cs.cs_quantity > 0 THEN 'Catalog' ELSE 'Store' END
ORDER BY total_net_paid DESC
LIMIT 100
