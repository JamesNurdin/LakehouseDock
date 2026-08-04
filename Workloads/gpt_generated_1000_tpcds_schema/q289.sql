WITH base_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_manufact_id,
        i.i_container,
        inv.inv_quantity_on_hand,
        ss.ss_ticket_number,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_tax,
        sr.sr_refunded_cash
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE ss.ss_net_paid_inc_tax > 1000
      AND ss.ss_ext_tax BETWEEN 0 AND 200
      AND i.i_manufact_id IN (117, 214)
      AND i.i_container = 'Unknown'
      AND inv.inv_quantity_on_hand > 500
),
agg_data AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_product_name,
        i_manufact_id,
        i_container,
        MAX(inv_quantity_on_hand) AS max_on_hand,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        SUM(sr_refunded_cash) AS total_refunds,
        COUNT(DISTINCT ss_ticket_number) AS sales_transactions,
        AVG(ss_ext_tax) AS avg_tax,
        CASE
            WHEN SUM(ss_net_paid_inc_tax) > SUM(sr_refunded_cash) THEN 'Profit'
            ELSE 'Loss'
        END AS profit_status
    FROM base_data
    GROUP BY i_item_sk, i_item_id, i_product_name, i_manufact_id, i_container
)
SELECT
    a.i_item_sk,
    a.i_item_id,
    a.i_product_name,
    a.i_manufact_id,
    a.i_container,
    a.max_on_hand,
    a.total_sales,
    a.total_refunds,
    a.sales_transactions,
    a.avg_tax,
    a.profit_status,
    ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS rn
FROM agg_data a
WHERE a.i_item_sk NOT IN (
    SELECT i_item_sk FROM item WHERE i_brand = 'ObscureBrand'
)
ORDER BY a.total_sales DESC
LIMIT 100
