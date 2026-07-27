WITH catalog_sales_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_sales,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_order_number = cs.cs_order_number
      )
    GROUP BY i.i_item_id, d.d_year
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = ws.ws_item_sk
      )
    GROUP BY i.i_item_id, d.d_year
)
SELECT i_item_id, d_year, total_sales, channel
FROM catalog_sales_agg
UNION ALL
SELECT i_item_id, d_year, total_sales, channel
FROM web_sales_agg
ORDER BY total_sales DESC
LIMIT 100
