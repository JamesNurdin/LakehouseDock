WITH
  -- Sample a fraction of the item table
  sampled_items AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)   -- approximately 10% of rows
  ),

  -- Order numbers that appear in both web_sales and web_returns
  order_numbers_intersect AS (
    SELECT ws_order_number AS order_number FROM web_sales
    INTERSECT
    SELECT wr_order_number FROM web_returns
  ),

  -- Full outer join of sales and returns, enriched with item, customer and web site data
  joined_sales_returns AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      i.i_item_desc,
      i.i_product_name,
      ws.ws_bill_cdemo_sk,
      cd.cd_gender,
      wsit.web_name,
      ls.site_prefix
    FROM web_sales ws
    FULL OUTER JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN sampled_items i
      ON i.i_item_sk = COALESCE(ws.ws_item_sk, wr.wr_item_sk)
    LEFT JOIN customer_demographics cd
      ON cd.cd_demo_sk = COALESCE(ws.ws_bill_cdemo_sk, wr.wr_refunded_cdemo_sk)
    LEFT JOIN web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    CROSS JOIN LATERAL (
      SELECT substr(wsit.web_name, 1, 10) AS site_prefix
    ) AS ls
    WHERE (
          ws.ws_sold_date_sk IS NOT NULL
          OR wr.wr_returned_date_sk IS NOT NULL
        )
      AND (
            regexp_like(i.i_item_desc, '^.*[Aa]dvanced.*$')
            OR i.i_item_desc IS NULL
          )
  ),

  -- Aggregate per order, filter with HAVING, and extract a code from the product name
  aggregated AS (
    SELECT
      COALESCE(ws_order_number, -1) AS order_number,
      COUNT(*) AS txn_count,
      SUM(ws_quantity) AS total_qty,
      SUM(COALESCE(ws_net_paid, 0)) - SUM(COALESCE(wr_net_loss, 0)) AS net_revenue,
      SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
      MAX(regexp_extract(i_product_name, '([A-Z]{3,})', 1)) AS extracted_code,
      MAX(site_prefix) AS site_prefix
    FROM joined_sales_returns
    GROUP BY COALESCE(ws_order_number, -1)
    HAVING SUM(ws_quantity) > 5
  )

SELECT
  a.order_number,
  a.txn_count,
  a.total_qty,
  a.net_revenue,
  a.male_customers,
  a.extracted_code,
  a.site_prefix,
  (
    SELECT COUNT(*)
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = COALESCE(a.order_number, 0)
  ) AS related_catalog_sales
FROM aggregated a
WHERE a.order_number IN (SELECT order_number FROM order_numbers_intersect)
ORDER BY a.net_revenue DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
