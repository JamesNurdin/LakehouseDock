WITH catalog_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_sign,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
        'catalog' AS src
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY GROUPING SETS ((d.d_year, i.i_category), (d.d_year), ())
),
web_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_sign,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
        'web' AS src
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY GROUPING SETS ((d.d_year, i.i_category), (d.d_year), ())
)
SELECT *
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
ORDER BY combined.d_year ASC,
         combined.profit_rank ASC,
         combined.src ASC
LIMIT 100
