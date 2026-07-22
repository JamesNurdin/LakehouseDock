WITH store_sales_agg AS (
    SELECT
        s.s_store_id AS entity_id,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'TX'
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
          WHERE i2.i_item_sk = ss.ss_item_sk
            AND cs2.cs_net_profit > 500
      )
    GROUP BY s.s_store_id, d.d_year
    HAVING SUM(ss.ss_net_profit) > (
        SELECT AVG(ss2.ss_net_profit) * 1.5
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year BETWEEN 2000 AND 2002
    )
)

SELECT
    'Store' AS entity_type,
    entity_id,
    year,
    total_net_profit
FROM store_sales_agg

UNION ALL

SELECT
    'CatalogPage' AS entity_type,
    cp.cp_catalog_page_id AS entity_id,
    d.d_year AS year,
    SUM(cs.cs_net_profit) AS total_net_profit
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND cp.cp_type = 'monthly'
  AND EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_order_number = cs.cs_order_number
        AND cr.cr_return_quantity > 0
  )
GROUP BY cp.cp_catalog_page_id, d.d_year
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY entity_type, total_net_profit DESC
LIMIT 100
