WITH base AS (
    SELECT
        d.d_year AS d_year,
        d.d_date AS d_date,
        s.s_store_id AS s_store_id,
        s.s_floor_space AS s_floor_space,
        t.t_hour AS t_hour,
        cp.cp_catalog_page_id AS cp_catalog_page_id,
        cp.cp_catalog_page_sk AS cp_catalog_page_sk,
        cs.cs_order_number AS cs_order_number,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_sales_price AS cs_sales_price,
        cs.cs_quantity AS cs_quantity,
        cr.cr_return_amount AS cr_return_amount,
        i.inv_quantity_on_hand AS inv_quantity_on_hand,
        w.w_state AS w_state,
        wp.wp_url AS wp_url,
        ws.web_site_id AS web_site_id
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON t.t_time_sk = ss.ss_sold_time_sk
    JOIN store s ON s.s_store_sk = ss.ss_store_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND cp.cp_type = 'Catalog'
        AND s.s_floor_space > 6000000
        AND t.t_hour BETWEEN 9 AND 17
        AND w.w_state = 'CA'
        AND cp.cp_description LIKE '%store%'
        AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            JOIN catalog_sales cs2 ON cr2.cr_order_number = cs2.cs_order_number
            WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
        )
        AND cs.cs_catalog_page_sk IN (
            SELECT cp2.cp_catalog_page_sk FROM catalog_page cp2 WHERE cp2.cp_department = 'Sports'
            INTERSECT
            SELECT cs2.cs_catalog_page_sk FROM catalog_sales cs2 WHERE cs2.cs_quantity > 5
        )
)
SELECT
    d_year,
    s_store_id,
    cp_catalog_page_id,
    t_hour,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_net_profit) AS total_net_profit,
    COALESCE(SUM(cr_return_amount), 0) AS total_return_amount,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    MIN(cs_sales_price) AS min_sales_price,
    MAX(cs_sales_price) AS max_sales_price
FROM base
GROUP BY d_year, s_store_id, cp_catalog_page_id, t_hour
ORDER BY total_net_paid DESC
LIMIT 100
