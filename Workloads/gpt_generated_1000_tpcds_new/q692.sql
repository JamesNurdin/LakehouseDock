WITH sampled_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_brand,
           i_class
    FROM item
    TABLESAMPLE BERNOULLI (10)
    WHERE regexp_like(i_product_name, '^[A-Z]{2,}')
      AND i_brand LIKE 'A%'
),
sales_agg AS (
    SELECT ws_item_sk,
           SUM(ws_net_paid) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451329 AND 2452575
    GROUP BY ws_item_sk
),
returns_agg AS (
    SELECT sr_item_sk,
           SUM(sr_net_loss) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2451329 AND 2452575
    GROUP BY sr_item_sk
),
high_sales_items AS (
    SELECT ws_item_sk AS i_item_sk
    FROM sales_agg
    WHERE total_sales > 1000
),
high_returns_items AS (
    SELECT sr_item_sk AS i_item_sk
    FROM returns_agg
    WHERE total_returns > 500
),
brand_pattern_items AS (
    SELECT i_item_sk
    FROM sampled_items
    WHERE i_brand LIKE 'A%'
      AND regexp_like(i_product_name, '^[A-Z]{3,}')
),
base_set AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           s.total_sales,
           r.total_returns,
           concat(i.i_brand, ':', i.i_class) AS brand_class,
           regexp_extract(i.i_product_name, '(\\d+)', 1) AS extracted_num,
           substring(i.i_product_name, 1, 5) AS product_prefix
    FROM sampled_items i
    JOIN sales_agg s ON i.i_item_sk = s.ws_item_sk
    JOIN returns_agg r ON i.i_item_sk = r.sr_item_sk
    WHERE i.i_item_sk NOT IN (
          SELECT i_item_sk FROM high_returns_items
          EXCEPT
          SELECT i_item_sk FROM high_sales_items
    )
)
SELECT *
FROM base_set
INTERSECT
SELECT *
FROM base_set
WHERE i_item_sk IN (SELECT i_item_sk FROM brand_pattern_items)
ORDER BY total_sales DESC
LIMIT 100
