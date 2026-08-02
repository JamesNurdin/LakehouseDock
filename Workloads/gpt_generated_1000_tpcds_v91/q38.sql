WITH sales_by_class AS (
    SELECT
        i.i_class AS item_class,
        'catalog' AS source,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        CASE
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE'
            WHEN SUM(cs.cs_net_profit) = 0 THEN 'ZERO'
            ELSE 'NEGATIVE'
        END AS profit_status
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND cs.cs_call_center_sk IN (
          SELECT cc_call_center_sk
          FROM call_center
          WHERE cc_division_name = 'cally'
      )
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = i.i_item_sk
      )
    GROUP BY i.i_class
),
returns_by_class AS (
    SELECT
        i.i_class AS item_class,
        'store_return' AS source,
        -SUM(sr.sr_return_amt) AS total_sales,
        SUM(sr.sr_return_quantity) AS total_quantity,
        CASE
            WHEN SUM(sr.sr_net_loss) > 0 THEN 'LOSS'
            ELSE 'NO_LOSS'
        END AS profit_status
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_item_sk IN (
          SELECT inv_item_sk
          FROM inventory
          WHERE inv_quantity_on_hand > 0
      )
    GROUP BY i.i_class
)
SELECT item_class, source, total_sales, total_quantity, profit_status
FROM sales_by_class
UNION ALL
SELECT item_class, source, total_sales, total_quantity, profit_status
FROM returns_by_class
ORDER BY item_class, source
LIMIT 100
