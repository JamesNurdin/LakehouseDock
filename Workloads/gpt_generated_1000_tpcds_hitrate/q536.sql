WITH agg AS (
    SELECT
        st.s_state AS state,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_tickets,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        GROUPING(st.s_state) AS g_state,
        GROUPING(i.i_category) AS g_category
    FROM store_sales ss
    JOIN time_dim td           ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i                ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store st              ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws          ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm          ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr       ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r              ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cd.cd_gender = 'M'
      AND i.i_current_price > 100
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
      AND i.i_item_sk IN (
            SELECT p2.p_item_sk
            FROM promotion p2
            WHERE p2.p_cost > 100
      )
      AND r.r_reason_desc LIKE '%warranty%'
    GROUP BY GROUPING SETS (
        (st.s_state, i.i_category),
        (st.s_state),
        (i.i_category),
        ()
    )
)
SELECT
    state,
    category,
    total_net_paid,
    total_net_profit,
    cnt_tickets,
    profit_flag,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS sales_rank
FROM agg
WHERE state IS NOT NULL OR category IS NOT NULL
ORDER BY total_net_paid DESC
LIMIT 100
