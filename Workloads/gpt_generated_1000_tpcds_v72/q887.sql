WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.s_store_id,
        d.d_year,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND w.w_gmt_offset = -8.00
      AND p.p_discount_active = 'Y'
      AND we.web_country = 'United States'
    GROUP BY c.c_customer_id,
             c.c_first_name,
             c.c_last_name,
             s.s_store_id,
             d.d_year,
             p.p_promo_name
    HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    s_store_id,
    d_year,
    p_promo_name,
    store_net_profit,
    web_net_profit,
    store_qty,
    web_qty,
    distinct_store_tickets,
    distinct_web_orders,
    RANK() OVER (PARTITION BY d_year ORDER BY (store_net_profit + web_net_profit) DESC) AS profit_rank,
    SUM(store_net_profit + web_net_profit) OVER (
        PARTITION BY d_year
        ORDER BY (store_net_profit + web_net_profit)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
