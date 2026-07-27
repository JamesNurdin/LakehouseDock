/*
Goal: Identify the highest‑profit catalog items for each warehouse sold to male customers, enrich the result with web‑sales performance and any store‑return reasons, and rank items by total catalog profit and by return quantity.
*/
WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_profit)               AS total_cs_profit,
        SUM(cs.cs_quantity)                 AS total_cs_qty,
        ROW_NUMBER() OVER (
            PARTITION BY cs.cs_warehouse_sk
            ORDER BY SUM(cs.cs_net_profit) DESC
        )                                   AS cs_profit_rank
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451195               -- filter a date range (surrogate keys)
      AND cs.cs_quantity > 2                                          -- only sizable orders
      AND cd.cd_gender = 'M'                                          -- male customers only
      AND cs.cs_net_paid > 0                                          -- paid orders
      AND EXISTS (
            SELECT 1
            FROM warehouse w2
            WHERE w2.w_warehouse_sk = cs.cs_warehouse_sk
              AND w2.w_suite_number = 'Suite H'                      -- keep only warehouses with this suite number
        )
    GROUP BY
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        i.i_item_id,
        i.i_product_name
)
SELECT
    sa.cs_warehouse_sk,
    w.w_warehouse_name,
    sa.i_item_id,
    sa.i_product_name,
    sa.total_cs_profit,
    sa.total_cs_qty,
    sa.cs_profit_rank,
    ws.ws_net_profit        AS web_net_profit,
    ws.ws_quantity          AS web_quantity,
    r.r_reason_desc,
    sr.sr_return_quantity,
    DENSE_RANK() OVER (
        PARTITION BY sa.cs_warehouse_sk
        ORDER BY sr.sr_return_quantity DESC
    )                        AS return_qty_rank
FROM sales_agg sa
JOIN warehouse w
    ON w.w_warehouse_sk = sa.cs_warehouse_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = sa.cs_item_sk
   AND ws.ws_warehouse_sk = sa.cs_warehouse_sk
   AND ws.ws_quantity > 1                                          -- modest web‑sale quantity filter
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = sa.cs_item_sk
LEFT JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
WHERE w.w_county = 'Franklin Parish'                                 -- keep only warehouses in this county
  AND sr.sr_return_tax > 2.00                                        -- filter returns with non‑trivial tax amount
ORDER BY
    sa.total_cs_profit DESC,
    return_qty_rank ASC
LIMIT 100
