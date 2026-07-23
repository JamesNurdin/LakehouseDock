WITH filtered_items AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_brand,
           i.i_product_name
    FROM item i
    WHERE regexp_like(i.i_product_name, '\\d')
      AND i.i_product_name LIKE 'A%'
),
catalog_sales_agg AS (
    SELECT cs.cs_item_sk AS item_sk,
           SUM(cs.cs_net_profit) AS total_catalog_net_profit
    FROM catalog_sales cs
    JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
    GROUP BY cs.cs_item_sk
),
web_sales_agg AS (
    SELECT ws.ws_item_sk AS item_sk,
           SUM(ws.ws_net_profit) AS total_web_net_profit
    FROM web_sales ws
    JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
    GROUP BY ws.ws_item_sk
),
returns_agg AS (
    SELECT item_sk,
           SUM(total_return_amount) AS total_return_amount
    FROM (
        SELECT sr.sr_item_sk AS item_sk,
               SUM(sr.sr_return_amt) AS total_return_amount
        FROM store_returns sr
        GROUP BY sr.sr_item_sk
        UNION ALL
        SELECT wr.wr_item_sk AS item_sk,
               SUM(wr.wr_return_amt) AS total_return_amount
        FROM web_returns wr
        GROUP BY wr.wr_item_sk
    ) t
    GROUP BY item_sk
)
SELECT
    fi.i_category,
    fi.i_brand,
    CONCAT(fi.i_brand, ' ', fi.i_product_name) AS brand_product_concat,
    SUBSTR(fi.i_product_name, 1, 10) AS product_name_prefix,
    REGEXP_EXTRACT(fi.i_product_name, '(\\d)') AS first_digit_extracted,
    COALESCE(cs.total_catalog_net_profit, 0) AS total_catalog_net_profit,
    COALESCE(ws.total_web_net_profit, 0) AS total_web_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE i2.i_category = fi.i_category
    ) AS avg_category_catalog_net_profit,
    EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = fi.i_item_sk
    ) AS has_store_return
FROM filtered_items fi
LEFT JOIN catalog_sales_agg cs ON fi.i_item_sk = cs.item_sk
LEFT JOIN web_sales_agg ws ON fi.i_item_sk = ws.item_sk
LEFT JOIN returns_agg r ON fi.i_item_sk = r.item_sk
ORDER BY total_catalog_net_profit DESC
LIMIT 100
