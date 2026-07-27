WITH filtered AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_manufact_id,
        i.i_rec_start_date,
        i.i_rec_end_date,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM tpcds.item i
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_manufact_id IN (117, 52)
        AND i.i_rec_start_date >= DATE '2000-01-01'
        AND i.i_rec_end_date <= DATE '2001-12-31'
        AND inv.inv_warehouse_sk = 11
        AND inv.inv_quantity_on_hand > 0
        AND ss.ss_ext_tax > 10
        AND ss.ss_cdemo_sk = 1014047
)
SELECT
    f.i_brand,
    f.i_category,
    f.inv_warehouse_sk,
    COUNT(DISTINCT f.ss_ticket_number) AS orders,
    SUM(f.ss_ext_sales_price) AS total_sales,
    AVG(f.ss_net_profit) AS avg_profit,
    MIN(f.ss_ext_tax) AS min_tax,
    MAX(f.ss_ext_tax) AS max_tax
FROM filtered f
GROUP BY f.i_brand, f.i_category, f.inv_warehouse_sk
ORDER BY total_sales DESC
LIMIT 100
