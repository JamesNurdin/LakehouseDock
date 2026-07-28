WITH sales_data AS (
    SELECT
        d.d_date,
        d.d_year,
        p.p_promo_name,
        p.p_channel_demo,
        w.w_city,
        w.w_state,
        w.w_warehouse_id,
        t.t_hour,
        ss.ss_net_profit,
        ss.ss_sales_price,
        ss.ss_ticket_number,
        i.inv_quantity_on_hand,
        wr.wr_return_quantity
    FROM
        store_sales ss
        INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
        LEFT JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_item_sk = ss.ss_item_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND p.p_channel_demo = 'N'
        AND w.w_state = 'CA'
        AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    d_date,
    p_promo_name,
    w_city,
    w_state,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
    COUNT(wr_return_quantity) AS total_returns
FROM
    sales_data
GROUP BY
    d_date,
    p_promo_name,
    w_city,
    w_state
HAVING
    SUM(ss_net_profit) > 10000
    AND COUNT(DISTINCT ss_ticket_number) > 100
ORDER BY
    total_profit DESC
LIMIT 100
