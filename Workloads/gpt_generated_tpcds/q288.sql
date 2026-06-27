-- Net profit and discount analysis per item across all sales channels (store, catalog, web)
WITH
store_sales_agg AS (
    SELECT
        ss_item_sk AS item_sk,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_net_profit) AS store_net_profit,
        SUM(ss_ext_discount_amt) AS store_discount_amt
    FROM store_sales
    GROUP BY ss_item_sk
),
store_returns_agg AS (
    SELECT
        sr_item_sk AS item_sk,
        SUM(sr_return_quantity) AS store_return_quantity,
        SUM(sr_net_loss) AS store_net_loss
    FROM store_returns
    GROUP BY sr_item_sk
),
catalog_sales_agg AS (
    SELECT
        cs_item_sk AS item_sk,
        SUM(cs_quantity) AS catalog_quantity,
        SUM(cs_net_profit) AS catalog_net_profit,
        SUM(cs_ext_discount_amt) AS catalog_discount_amt
    FROM catalog_sales
    GROUP BY cs_item_sk
),
catalog_returns_agg AS (
    SELECT
        cr_item_sk AS item_sk,
        SUM(cr_return_quantity) AS catalog_return_quantity,
        SUM(cr_net_loss) AS catalog_net_loss
    FROM catalog_returns
    GROUP BY cr_item_sk
),
web_sales_agg AS (
    SELECT
        ws_item_sk AS item_sk,
        SUM(ws_quantity) AS web_quantity,
        SUM(ws_net_profit) AS web_net_profit,
        SUM(ws_ext_discount_amt) AS web_discount_amt
    FROM web_sales
    GROUP BY ws_item_sk
),
web_returns_agg AS (
    SELECT
        wr_item_sk AS item_sk,
        SUM(wr_return_quantity) AS web_return_quantity,
        SUM(wr_net_loss) AS web_net_loss
    FROM web_returns
    GROUP BY wr_item_sk
),
item_aggregates AS (
    SELECT
        i.i_item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        COALESCE(store_sales_agg.store_quantity, 0) +
        COALESCE(catalog_sales_agg.catalog_quantity, 0) +
        COALESCE(web_sales_agg.web_quantity, 0) AS total_quantity_sold,
        COALESCE(store_sales_agg.store_net_profit, 0) +
        COALESCE(catalog_sales_agg.catalog_net_profit, 0) +
        COALESCE(web_sales_agg.web_net_profit, 0) AS total_net_profit,
        COALESCE(store_returns_agg.store_return_quantity, 0) +
        COALESCE(catalog_returns_agg.catalog_return_quantity, 0) +
        COALESCE(web_returns_agg.web_return_quantity, 0) AS total_quantity_returned,
        COALESCE(store_returns_agg.store_net_loss, 0) +
        COALESCE(catalog_returns_agg.catalog_net_loss, 0) +
        COALESCE(web_returns_agg.web_net_loss, 0) AS total_net_loss,
        COALESCE(store_sales_agg.store_discount_amt, 0) +
        COALESCE(catalog_sales_agg.catalog_discount_amt, 0) +
        COALESCE(web_sales_agg.web_discount_amt, 0) AS total_discount_amount
    FROM item i
    LEFT JOIN store_sales_agg ON i.i_item_sk = store_sales_agg.item_sk
    LEFT JOIN catalog_sales_agg ON i.i_item_sk = catalog_sales_agg.item_sk
    LEFT JOIN web_sales_agg ON i.i_item_sk = web_sales_agg.item_sk
    LEFT JOIN store_returns_agg ON i.i_item_sk = store_returns_agg.item_sk
    LEFT JOIN catalog_returns_agg ON i.i_item_sk = catalog_returns_agg.item_sk
    LEFT JOIN web_returns_agg ON i.i_item_sk = web_returns_agg.item_sk
)
SELECT
    item_id,
    product_name,
    category,
    brand,
    total_quantity_sold,
    total_quantity_returned,
    total_net_profit - total_net_loss AS net_profit_after_returns,
    total_discount_amount,
    CASE
        WHEN total_quantity_sold > 0 THEN total_discount_amount / total_quantity_sold
        ELSE 0
    END AS avg_discount_per_unit
FROM item_aggregates
WHERE total_quantity_sold > 0
ORDER BY net_profit_after_returns DESC
LIMIT 20
