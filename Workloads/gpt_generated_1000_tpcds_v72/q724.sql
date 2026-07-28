WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_brand,
        cd.cd_gender,
        td.t_shift,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(*) AS transaction_cnt,
        CASE
            WHEN SUM(COALESCE(cr.cr_return_amount, 0)) > 0 THEN 'HasReturn'
            ELSE 'NoReturn'
        END AS return_flag
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20.00
      AND td.t_shift = 'first'
      AND cd.cd_gender = 'M'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY
        i.i_item_id,
        i.i_category,
        i.i_brand,
        cd.cd_gender,
        td.t_shift
), avg_sales AS (
    SELECT AVG(store_sales_total) AS avg_store_sales
    FROM sales_agg
)
SELECT
    sa.i_item_id,
    sa.i_category,
    sa.i_brand,
    sa.t_shift,
    sa.store_sales_total,
    sa.catalog_sales_total,
    sa.total_returns,
    sa.return_flag,
    avg_tbl.avg_store_sales,
    ROW_NUMBER() OVER (ORDER BY sa.store_sales_total DESC) AS sales_rank
FROM sales_agg sa
CROSS JOIN avg_sales avg_tbl
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    JOIN item i2 ON cr2.cr_item_sk = i2.i_item_sk
    WHERE i2.i_item_id = sa.i_item_id
      AND cr2.cr_return_amount > 0
)
ORDER BY sa.store_sales_total DESC
LIMIT 100
