WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        d.d_year,
        s.s_store_sk,
        ws.ws_web_page_sk,
        SUM(ss.ss_ext_sales_price)               AS store_sales_amount,
        SUM(ss.ss_net_profit)                     AS store_profit,
        COUNT(DISTINCT ss.ss_ticket_number)       AS store_transactions,
        SUM(ws.ws_ext_sales_price)                AS web_sales_amount,
        SUM(ws.ws_net_profit)                     AS web_profit,
        COUNT(DISTINCT ws.ws_order_number)        AS web_transactions,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_active_count
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN time_dim t        ON ss.ss_sold_time_sk   = t.t_time_sk
    JOIN item i            ON ss.ss_item_sk        = i.i_item_sk
    JOIN customer c        ON ss.ss_customer_sk    = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca      ON ss.ss_addr_sk   = ca.ca_address_sk
    JOIN store s           ON ss.ss_store_sk      = s.s_store_sk
    JOIN promotion p       ON ss.ss_promo_sk      = p.p_promo_sk
    LEFT JOIN store_returns sr      ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r              ON sr.sr_reason_sk     = r.r_reason_sk
    LEFT JOIN inventory inv         ON inv.inv_item_sk = i.i_item_sk
                                   AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws          ON ws.ws_item_sk   = i.i_item_sk
                                   AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr        ON wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND c.c_birth_year = 1965
      AND i.i_color = 'Red'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 500
      AND t.t_meal_time = 'dinner'
      AND wp.wp_type = 'content'
    GROUP BY i.i_item_sk, i.i_item_id, d.d_year, s.s_store_sk, ws.ws_web_page_sk
),
filtered AS (
    SELECT *
    FROM (
        SELECT i_item_sk, i_item_id, store_sales_amount, web_sales_amount, store_profit
        FROM sales_agg
    )
    EXCEPT
    SELECT i_item_sk, i_item_id, store_sales_amount, web_sales_amount, store_profit
    FROM sales_agg
    WHERE web_sales_amount > 0
)
SELECT
    f.i_item_sk,
    f.i_item_id,
    f.store_sales_amount,
    f.web_sales_amount,
    f.store_profit,
    CASE WHEN f.store_sales_amount > 0 THEN f.store_profit / f.store_sales_amount ELSE NULL END AS profit_per_sale
FROM filtered f
WHERE f.store_profit > (SELECT AVG(store_profit) FROM sales_agg)
ORDER BY f.store_profit DESC
LIMIT 100
