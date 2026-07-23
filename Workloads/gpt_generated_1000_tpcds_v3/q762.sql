WITH catalog_agg AS (
    SELECT i.i_item_id AS item_id,
           'Catalog' AS sales_channel,
           SUM(cs.cs_net_paid_inc_ship) AS total_sales,
           SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
    GROUP BY i.i_item_id
),
store_agg AS (
    SELECT i.i_item_id AS item_id,
           'Store' AS sales_channel,
           SUM(ss.ss_net_paid) AS total_sales,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_current_price > 100.00
    GROUP BY i.i_item_id
)
SELECT item_id,
       sales_channel,
       total_sales,
       total_quantity,
       ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT item_id, sales_channel, total_sales, total_quantity FROM catalog_agg
    UNION ALL
    SELECT item_id, sales_channel, total_sales, total_quantity FROM store_agg
) combined
ORDER BY total_sales DESC
LIMIT 100
