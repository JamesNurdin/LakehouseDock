WITH sales_agg AS (
    SELECT
        p.p_promo_name               AS p_promo_name,
        sm.sm_type                    AS sm_type,
        r.r_reason_desc               AS r_reason_desc,
        t.t_hour                      AS t_hour,
        c.c_customer_id               AS c_customer_id,
        SUM(ws.ws_net_profit)         AS total_profit,
        SUM(ws.ws_quantity)           AS total_quantity,
        SUM(wr.wr_return_amt)         AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN promotion p   ON ws.ws_promo_sk      = p.p_promo_sk
    JOIN ship_mode sm  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t    ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c    ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp   ON ws.ws_web_page_sk   = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                              AND ws.ws_item_sk     = wr.wr_item_sk
    LEFT JOIN reason r       ON wr.wr_reason_sk   = r.r_reason_sk
    WHERE p.p_channel_email   = 'Y'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type          = 'AIR'
      AND t.t_hour BETWEEN 9 AND 17
      AND c.c_birth_year   > 1980
      AND wp.wp_link_count > 5
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc LIKE '%damage%')
    GROUP BY ROLLUP (p.p_promo_name, sm.sm_type, r.r_reason_desc, t.t_hour, c.c_customer_id)
)
SELECT
    p_promo_name,
    sm_type,
    r_reason_desc,
    t_hour,
    c_customer_id,
    total_profit,
    total_quantity,
    total_return_amount,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY sm_type, profit_rank
LIMIT 100
