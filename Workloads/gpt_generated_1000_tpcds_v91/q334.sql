WITH q1 AS (
    SELECT
        p.p_promo_name,
        p.p_discount_active,
        td.t_meal_time,
        td.t_hour,
        wp.wp_type,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_txn,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
        AVG(ss.ss_ext_tax) AS avg_store_tax,
        SUM(CASE WHEN sr.sr_return_quantity IS NULL THEN 0 ELSE sr.sr_return_quantity END) AS total_store_return_qty,
        SUM(CASE WHEN wr.wr_return_quantity IS NULL THEN 0 ELSE wr.wr_return_quantity END) AS total_web_return_qty,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
    FROM
        time_dim td
        INNER JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
        INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                                  AND sr.sr_ticket_number = ss.ss_ticket_number
                                  AND sr.sr_return_time_sk = td.t_time_sk
        INNER JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
        INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
                                 AND wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_returned_time_sk = td.t_time_sk
                                 AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        p.p_promo_name = 'Holiday Promo'
        AND td.t_meal_time = 'dinner'
        AND ss.ss_list_price > 50
        AND ws.ws_net_paid_inc_tax > 1000
        AND wp.wp_type = 'product'
    GROUP BY
        p.p_promo_name,
        p.p_discount_active,
        td.t_meal_time,
        td.t_hour,
        wp.wp_type
),
q2 AS (
    SELECT
        p.p_promo_name,
        p.p_discount_active,
        td.t_meal_time,
        td.t_hour,
        wp.wp_type,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_txn,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
        AVG(ss.ss_ext_tax) AS avg_store_tax,
        SUM(CASE WHEN sr.sr_return_quantity IS NULL THEN 0 ELSE sr.sr_return_quantity END) AS total_store_return_qty,
        SUM(CASE WHEN wr.wr_return_quantity IS NULL THEN 0 ELSE wr.wr_return_quantity END) AS total_web_return_qty,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
    FROM
        time_dim td
        INNER JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
        INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                                  AND sr.sr_ticket_number = ss.ss_ticket_number
                                  AND sr.sr_return_time_sk = td.t_time_sk
        INNER JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
        INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
                                 AND wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_returned_time_sk = td.t_time_sk
                                 AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        p.p_promo_name = 'Clearance Sale'
        AND td.t_meal_time = 'lunch'
        AND ss.ss_list_price > 30
        AND ws.ws_net_paid_inc_tax > 500
        AND wp.wp_type = 'product'
    GROUP BY
        p.p_promo_name,
        p.p_discount_active,
        td.t_meal_time,
        td.t_hour,
        wp.wp_type
)
SELECT *
FROM (
    SELECT * FROM q1
    UNION
    SELECT * FROM q2
) combined
ORDER BY total_store_sales DESC
LIMIT 100
