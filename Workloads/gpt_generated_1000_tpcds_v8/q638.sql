WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY inv_item_sk
  ),
  store_agg AS (
    SELECT
      ss_item_sk,
      SUM(ss_net_paid) AS store_net_paid,
      SUM(ss_net_profit) AS store_net_profit,
      COUNT(DISTINCT ss_customer_sk) AS store_customer_cnt
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_sales_price > 0
      AND ss_ext_tax >= 0
      AND ss_net_paid IS NOT NULL
    GROUP BY ss_item_sk
  ),
  web_agg AS (
    SELECT
      ws_item_sk,
      SUM(ws_net_paid) AS web_net_paid,
      SUM(ws_net_profit) AS web_net_profit,
      COUNT(DISTINCT ws_bill_customer_sk) AS web_customer_cnt
    FROM web_sales
    WHERE ws_quantity > 0
      AND ws_sales_price > 0
      AND ws_ext_tax >= 0
      AND ws_net_paid IS NOT NULL
    GROUP BY ws_item_sk
  ),
  union_agg AS (
    SELECT
      item_sk,
      total_sales,
      total_profit,
      customer_cnt
    FROM (
      SELECT
        ss_item_sk AS item_sk,
        store_net_paid AS total_sales,
        store_net_profit AS total_profit,
        store_customer_cnt AS customer_cnt
      FROM store_agg
      UNION
      SELECT
        ws_item_sk AS item_sk,
        web_net_paid AS total_sales,
        web_net_profit AS total_profit,
        web_customer_cnt AS customer_cnt
      FROM web_agg
    )
  ),
  final AS (
    SELECT
      i.i_item_id AS item_id,
      i.i_category AS category,
      i.i_brand AS brand,
      i.i_product_name AS product_name,
      cp.cp_department AS department,
      wsit.web_name AS web_name,
      ua.total_sales,
      ua.total_profit,
      ua.customer_cnt,
      ia.total_on_hand,
      (
        SELECT AVG(cs_ext_discount_amt)
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = i.i_item_sk
      ) AS avg_catalog_discount,
      (
        SELECT MAX(cs_sales_price)
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = i.i_item_sk
      ) AS max_catalog_sales_price,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ua.total_profit DESC) AS profit_rank,
      lc.distinct_store_customers
    FROM item i
    FULL OUTER JOIN store_agg sa ON i.i_item_sk = sa.ss_item_sk
    LEFT JOIN inv_agg ia ON i.i_item_sk = ia.inv_item_sk
    LEFT JOIN union_agg ua ON i.i_item_sk = ua.item_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN LATERAL (
      SELECT COUNT(DISTINCT ss_customer_sk) AS distinct_store_customers
      FROM store_sales ss
      WHERE ss.ss_item_sk = i.i_item_sk
    ) lc ON TRUE
    WHERE i.i_current_price BETWEEN 10 AND 1000
      AND i.i_brand_id IS NOT NULL
      AND cp.cp_department = 'Books'
      AND wsit.web_country = 'United States'
      AND cd.cd_gender = 'M'
      AND wr.wr_return_quantity > 0
      AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_net_loss > 0
      )
  )
SELECT
  item_id,
  category,
  brand,
  product_name,
  department,
  web_name,
  total_sales,
  total_profit,
  customer_cnt,
  total_on_hand,
  avg_catalog_discount,
  max_catalog_sales_price,
  profit_rank,
  distinct_store_customers
FROM final
WHERE profit_rank <= 10
ORDER BY category, profit_rank
LIMIT 100
