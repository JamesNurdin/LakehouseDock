WITH catalog_part AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
      AND cs.cs_net_profit > 1000
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY d.d_date, i.i_item_id
),
store_part AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        'store' AS source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_geography_class = 'Unknown'
      AND ss.ss_net_profit > 1000
      AND i.i_manager_id IN (
          SELECT i2.i_manager_id
          FROM item i2
          JOIN inventory inv2 ON i2.i_item_sk = inv2.inv_item_sk
          GROUP BY i2.i_manager_id
          HAVING SUM(inv2.inv_quantity_on_hand) > 5000
      )
    GROUP BY d.d_date, i.i_item_id
)
SELECT sale_date,
       i_item_id,
       total_sales,
       total_profit,
       source
FROM catalog_part
UNION ALL
SELECT sale_date,
       i_item_id,
       total_sales,
       total_profit,
       source
FROM store_part
ORDER BY sale_date DESC, total_sales DESC
LIMIT 100
