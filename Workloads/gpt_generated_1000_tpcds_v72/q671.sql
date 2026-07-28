WITH joined_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_manufact_id,
        cs.cs_ext_sales_price AS cs_sales,
        cs.cs_ext_ship_cost AS cs_ship_cost,
        cs.cs_net_profit AS cs_profit,
        inv.inv_quantity_on_hand,
        ss.ss_ext_sales_price AS ss_sales,
        ss.ss_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM
        item i
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE
        inv.inv_warehouse_sk IN (3, 14)
        AND i.i_manufact_id = 52
        AND cs.cs_net_paid_inc_ship > 1000
        AND ss.ss_quantity > 5
)
SELECT
    i_item_sk,
    i_item_id,
    i_product_name,
    i_manufact_id,
    SUM(cs_sales) AS total_catalog_sales,
    SUM(ss_sales) AS total_store_sales,
    SUM(wr_return_amt) AS total_returns,
    MAX(inv_quantity_on_hand) AS latest_inventory,
    (SUM(cs_sales) + SUM(ss_sales) - SUM(wr_return_amt)) / NULLIF((SUM(cs_sales) + SUM(ss_sales)), 0) AS net_margin
FROM
    joined_data
GROUP BY
    i_item_sk,
    i_item_id,
    i_product_name,
    i_manufact_id
HAVING
    (SUM(cs_sales) + SUM(ss_sales) - SUM(wr_return_amt)) > 500
    AND ( (SUM(cs_sales) + SUM(ss_sales) - SUM(wr_return_amt)) / NULLIF((SUM(cs_sales) + SUM(ss_sales)), 0) ) > 0.05
ORDER BY
    net_margin DESC,
    total_catalog_sales DESC
LIMIT 100
