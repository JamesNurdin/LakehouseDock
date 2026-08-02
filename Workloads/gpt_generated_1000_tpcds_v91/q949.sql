WITH sales_item_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_manager_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_count,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_net_paid) AS avg_net_paid,
        CASE
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_status
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE
        cs.cs_ship_cdemo_sk IN (144262, 1913884, 893739, 851058, 147343)
        AND cs.cs_net_paid > 1000
        AND i.i_manager_id IN (27, 44, 64)
        AND i.i_rec_end_date >= DATE '1999-01-01'
        AND i.i_rec_end_date <= DATE '2002-12-31'
    GROUP BY
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_manager_id
)
SELECT
    sai.i_item_sk,
    sai.i_product_name,
    sai.i_brand,
    sai.i_manager_id,
    sai.total_sales,
    sai.total_profit,
    sai.sales_count,
    sai.total_quantity,
    sai.avg_net_paid,
    sai.profit_status,
    inv.inv_quantity_on_hand,
    (SELECT AVG(cs2.cs_net_paid)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = sai.i_item_sk) AS overall_item_avg_net_paid,
    ROW_NUMBER() OVER (ORDER BY sai.total_sales DESC) AS row_num,
    SUM(sai.total_sales) OVER (PARTITION BY sai.i_brand) AS brand_total_sales
FROM sales_item_agg sai
JOIN inventory inv
    ON inv.inv_item_sk = sai.i_item_sk
WHERE inv.inv_quantity_on_hand > 0
ORDER BY sai.total_sales DESC
LIMIT 100
