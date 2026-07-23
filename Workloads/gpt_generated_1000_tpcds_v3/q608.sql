WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        i.i_brand,
        i.i_color,
        i.i_current_price,
        regexp_extract(i.i_item_desc, '(\\d{3,})', 1) AS extracted_code,
        CONCAT(i.i_brand, '-', i.i_color) AS brand_color
    FROM
        item i
    WHERE
        regexp_like(i.i_item_desc, '[0-9]{3}')
        AND i.i_item_desc LIKE '%blue%'
)
SELECT
    s.s_store_name,
    f.brand_color,
    f.extracted_code,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    AVG(ss.ss_net_profit) AS avg_profit_per_sale,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
    ) AS overall_avg_profit
FROM
    filtered_items f
    JOIN store_sales ss ON ss.ss_item_sk = f.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = f.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    cp.cp_description LIKE '%gift%'
    AND EXISTS (
        SELECT 1
        FROM inventory inv
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE inv.inv_item_sk = f.i_item_sk
          AND w.w_warehouse_sk = cr.cr_warehouse_sk
          AND inv.inv_quantity_on_hand > 100
    )
GROUP BY
    s.s_store_name,
    f.brand_color,
    f.extracted_code
HAVING
    SUM(ss.ss_net_profit) > 2 * (
        SELECT AVG(ss3.ss_net_profit)
        FROM store_sales ss3
    )
ORDER BY
    total_profit DESC
LIMIT 100
