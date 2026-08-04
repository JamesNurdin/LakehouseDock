WITH sales_data AS (
    SELECT
        i.i_category_id,
        w.w_city,
        ss.ss_ext_sales_price,
        cr.cr_refunded_cash,
        ss.ss_ticket_number,
        ss.ss_sales_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
      AND ss.ss_sold_date_sk = 2451088
      AND i.i_category_id = 4
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 700
)
SELECT
    i_category_id,
    w_city,
    SUM(ss_ext_sales_price)        AS total_sales,
    AVG(cr_refunded_cash)          AS avg_refund_cash,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    MIN(ss_sales_price)            AS min_sales_price,
    MAX(ss_sales_price)            AS max_sales_price
FROM sales_data
GROUP BY i_category_id, w_city

UNION DISTINCT

SELECT
    i_category_id,
    w_city,
    SUM(ss_ext_sales_price)        AS total_sales,
    AVG(cr_refunded_cash)          AS avg_refund_cash,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    MIN(ss_sales_price)            AS min_sales_price,
    MAX(ss_sales_price)            AS max_sales_price
FROM (
    SELECT
        i.i_category_id,
        w.w_city,
        ss.ss_ext_sales_price,
        cr.cr_refunded_cash,
        ss.ss_ticket_number,
        ss.ss_sales_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
      AND ss.ss_sold_date_sk = 2451102
      AND i.i_category_id = 7
      AND w.w_state = 'TX'
      AND inv.inv_quantity_on_hand > 650
) t
GROUP BY i_category_id, w_city
ORDER BY total_sales DESC
LIMIT 100
