WITH sales_inventory AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_sk,
        w.w_city,
        MAX(i.i_units) AS units,
        MAX(i.i_size) AS size,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty_sold,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_units IN ('Dozen', 'Cup')
      AND i.i_size NOT LIKE 'N/A'
      AND w.w_city IN ('Pine Grove', 'Greenwood')
      AND w.w_gmt_offset = -5.00
      AND ss.ss_net_paid_inc_tax > 500
      AND inv.inv_quantity_on_hand > 0
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, w.w_warehouse_sk, w.w_city
),
returns_agg AS (
    SELECT
        i.i_item_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY i.i_item_sk
)
SELECT DISTINCT
    si.i_item_id,
    si.i_product_name,
    si.w_city,
    si.units,
    si.size,
    si.total_sales,
    si.total_on_hand,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    (si.total_sales - COALESCE(ra.total_return_amount, 0)) AS net_sales_minus_returns
FROM sales_inventory si
LEFT JOIN returns_agg ra ON si.i_item_sk = ra.i_item_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = si.i_item_sk
)
ORDER BY net_sales_minus_returns DESC
LIMIT 100
