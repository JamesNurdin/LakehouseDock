WITH cs_data AS (
    SELECT
        cs.cs_item_sk                                           AS item_sk,
        i.i_item_id                                            AS i_item_id,
        w.w_warehouse_name                                      AS w_warehouse_name,
        SUM(cs.cs_ext_sales_price)                             AS total_sales,
        SUM(cs.cs_net_profit)                                  AS total_profit
    FROM catalog_sales cs
    FULL OUTER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE (td.t_hour BETWEEN 9 AND 17 OR td.t_hour IS NULL)
      AND NOT EXISTS (
          SELECT 1 FROM web_sales ws_sub
          WHERE ws_sub.ws_order_number = cs.cs_order_number
      )
    GROUP BY cs.cs_item_sk, i.i_item_id, w.w_warehouse_name
),
ws_data AS (
    SELECT
        ws.ws_item_sk                                           AS item_sk,
        i.i_item_id                                            AS i_item_id,
        w.w_warehouse_name                                      AS w_warehouse_name,
        SUM(ws.ws_ext_sales_price)                             AS total_sales,
        SUM(ws.ws_net_profit)                                  AS total_profit
    FROM web_sales ws
    FULL OUTER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE (td.t_hour BETWEEN 9 AND 17 OR td.t_hour IS NULL)
      AND NOT EXISTS (
          SELECT 1 FROM catalog_sales cs_sub
          WHERE cs_sub.cs_order_number = ws.ws_order_number
      )
    GROUP BY ws.ws_item_sk, i.i_item_id, w.w_warehouse_name
),
all_sales AS (
    SELECT * FROM cs_data
    UNION ALL
    SELECT * FROM ws_data
)
SELECT
    item_sk,
    i_item_id,
    w_warehouse_name,
    total_sales,
    total_profit,
    CASE
        WHEN total_profit >= 10000 THEN 'High'
        WHEN total_profit >= 0     THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM all_sales
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
