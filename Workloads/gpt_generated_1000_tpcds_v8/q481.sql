WITH
  filtered_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word,
           substr(i.i_product_name, 1, 15) AS short_name
    FROM tpcds.item AS i
    TABLESAMPLE BERNOULLI (5)
    WHERE i.i_product_name LIKE '%Gold%'
      AND regexp_like(i.i_product_name, '[0-9]{2}')
  ),
  catalog_item_sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           sum(cs.cs_net_paid) AS total_sales,
           count(*) AS order_count
    FROM tpcds.catalog_sales cs
    JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
    GROUP BY cs.cs_item_sk
  ),
  store_item_sales AS (
    SELECT ss.ss_item_sk AS item_sk,
           sum(ss.ss_net_paid) AS total_sales,
           count(*) AS order_count
    FROM tpcds.store_sales ss
    JOIN filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
    GROUP BY ss.ss_item_sk
  ),
  union_sales AS (
    SELECT item_sk, total_sales, order_count FROM catalog_item_sales
    UNION
    SELECT item_sk, total_sales, order_count FROM store_item_sales
  ),
  returned_items AS (
    SELECT wr.wr_item_sk AS item_sk,
           sum(wr.wr_return_amt) AS total_returns,
           count(*) AS return_count
    FROM tpcds.web_returns wr
    JOIN filtered_items fi ON wr.wr_item_sk = fi.i_item_sk
    GROUP BY wr.wr_item_sk
  ),
  sales_without_returns AS (
    SELECT us.item_sk, us.total_sales, us.order_count
    FROM union_sales us
    EXCEPT
    SELECT ri.item_sk, ri.total_returns, ri.return_count FROM returned_items ri
  ),
  common_items AS (
    SELECT us.item_sk FROM union_sales us
    INTERSECT
    SELECT ri.item_sk FROM returned_items ri
  )
SELECT
  fi.i_item_sk,
  fi.i_product_name,
  fi.first_word,
  fi.short_name,
  coalesce(us.total_sales, 0) AS total_sales,
  coalesce(us.order_count, 0) AS total_orders,
  coalesce(ri.total_returns, 0) AS total_returns,
  CASE WHEN ri.item_sk IS NOT NULL THEN 'Returned' ELSE 'Not Returned' END AS return_status
FROM filtered_items fi
LEFT JOIN sales_without_returns us ON fi.i_item_sk = us.item_sk
LEFT JOIN returned_items ri ON fi.i_item_sk = ri.item_sk
WHERE fi.i_item_sk IN (SELECT item_sk FROM common_items)
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
