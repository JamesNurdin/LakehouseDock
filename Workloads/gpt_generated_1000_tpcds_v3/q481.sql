WITH base_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_item_sk,
        d.d_date,
        c.c_preferred_cust_flag,
        c.c_first_name,
        c.c_last_name,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND p.p_discount_active = 'Y'
      AND d.d_holiday = 'N'
)
SELECT
    bs.ss_ticket_number,
    bs.s_store_name,
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    d2.d_date AS ws_sold_date,
    ws.ws_net_paid AS web_net_paid,
    bs.ss_net_paid AS store_net_paid,
    bs.ss_net_profit,
    ws.ws_net_profit AS web_net_profit,
    p2.p_promo_name AS web_promo_name,
    sm.sm_type AS ship_mode_type,
    CASE
        WHEN ws.ws_net_profit > bs.ss_net_profit THEN 'Web Better'
        ELSE 'Store Better'
    END AS profit_comparison,
    ROW_NUMBER() OVER (PARTITION BY bs.ss_store_sk ORDER BY (bs.ss_net_profit + ws.ws_net_profit) DESC) AS sales_rank
FROM base_sales bs
JOIN web_sales ws ON ws.ws_bill_customer_sk = bs.ss_customer_sk
JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = bs.ss_ticket_number
          AND sr.sr_return_quantity > 0
          AND sr.sr_return_amt > 10
    )
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_return_quantity > 0
          AND wr.wr_return_amt > 20
    )
  AND wp.wp_type = 'product'
  AND sm.sm_type = 'AIR'
  AND d2.d_month_seq BETWEEN 1200 AND 1212
ORDER BY sales_rank, bs.ss_ticket_number
LIMIT 100
