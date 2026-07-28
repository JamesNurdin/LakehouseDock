WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_return_amt
    FROM store_sales ss
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    SUM(bs.ss_ext_sales_price) AS total_sales,
    SUM(bs.ss_net_profit) AS total_profit,
    SUM(COALESCE(bs.sr_return_amt, 0)) AS total_returns,
    RANK() OVER (PARTITION BY d_sales.d_year ORDER BY SUM(bs.ss_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(bs.ss_net_profit) > (
            SELECT AVG(net_profit)
            FROM (
                SELECT SUM(ss2.ss_net_profit) AS net_profit
                FROM store_sales ss2
                GROUP BY ss2.ss_sold_date_sk
            ) avg_sub
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    w.w_warehouse_name,
    sm.sm_type,
    we.web_name
FROM
    base_sales bs
    JOIN date_dim d_sales ON bs.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t ON bs.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON bs.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON bs.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON bs.ss_store_sk = s.s_store_sk
    JOIN promotion p ON bs.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE
    EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_warehouse_sk = w.w_warehouse_sk
          AND i.inv_date_sk = d_ship.d_date_sk
          AND i.inv_quantity_on_hand > 0
    )
    AND hd.hd_vehicle_count > 0
    AND p.p_discount_active = 'Y'
    AND d_sales.d_year = 1998
    AND sm.sm_type = 'AIR'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    w.w_warehouse_name,
    sm.sm_type,
    we.web_name
ORDER BY
    total_sales DESC
LIMIT 100
