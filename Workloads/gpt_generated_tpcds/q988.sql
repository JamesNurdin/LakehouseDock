WITH sales AS (
    SELECT ws_item_sk AS i_item_sk,
           SUM(ws_quantity) AS total_quantity_sold,
           SUM(ws_ext_sales_price) AS total_sales_amount,
           SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
store_returns_agg AS (
    SELECT sr_item_sk AS i_item_sk,
           SUM(sr_return_quantity) AS total_store_return_qty,
           SUM(sr_return_amt) AS total_store_return_amt,
           SUM(sr_net_loss) AS total_store_net_loss
    FROM store_returns
    GROUP BY sr_item_sk
),
catalog_returns_agg AS (
    SELECT cr_item_sk AS i_item_sk,
           SUM(cr_return_quantity) AS total_catalog_return_qty,
           SUM(cr_return_amount) AS total_catalog_return_amt,
           SUM(cr_net_loss) AS total_catalog_net_loss
    FROM catalog_returns
    GROUP BY cr_item_sk
)
SELECT i.i_item_id,
       i.i_product_name,
       i.i_brand,
       i.i_category,
       COALESCE(s.total_quantity_sold, 0) AS total_quantity_sold,
       COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
       COALESCE(s.total_net_profit, 0) AS total_net_profit,
       COALESCE(sr.total_store_return_qty, 0) AS total_store_return_qty,
       COALESCE(sr.total_store_return_amt, 0) AS total_store_return_amt,
       COALESCE(cr.total_catalog_return_qty, 0) AS total_catalog_return_qty,
       COALESCE(cr.total_catalog_return_amt, 0) AS total_catalog_return_amt,
       CAST((COALESCE(sr.total_store_return_qty, 0) + COALESCE(cr.total_catalog_return_qty, 0)) AS double) /
           NULLIF(COALESCE(s.total_quantity_sold, 0), 0) AS total_return_rate,
       ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY COALESCE(s.total_sales_amount, 0) DESC) AS brand_item_rank
FROM item i
LEFT JOIN sales s ON i.i_item_sk = s.i_item_sk
LEFT JOIN store_returns_agg sr ON i.i_item_sk = sr.i_item_sk
LEFT JOIN catalog_returns_agg cr ON i.i_item_sk = cr.i_item_sk
WHERE i.i_current_price > 0
ORDER BY total_sales_amount DESC
LIMIT 50
