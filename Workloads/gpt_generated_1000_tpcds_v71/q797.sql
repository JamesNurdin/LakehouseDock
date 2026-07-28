/* Goal: Rank warehouses by net profit for catalog sales in 2001, enriched with item, inventory, store/web sales and return information, classifying profit levels and showing average item profit */
WITH catalog_with_avg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_order_number,
        cs.cs_net_profit,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = cs.cs_item_sk
        ) AS avg_item_profit
    FROM catalog_sales cs
)
SELECT
    w.w_warehouse_sk,
    w.w_warehouse_name,
    d.d_year,
    i.i_item_id,
    cs_avg.cs_order_number,
    cs_avg.cs_net_profit,
    CASE WHEN cs_avg.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    cs_avg.avg_item_profit,
    r.r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY cs_avg.cs_net_profit DESC) AS rn_profit_rank
FROM catalog_with_avg cs_avg
JOIN date_dim d
  ON cs_avg.cs_sold_date_sk = d.d_date_sk
JOIN item i
  ON cs_avg.cs_item_sk = i.i_item_sk
JOIN household_demographics hd
  ON cs_avg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm
  ON cs_avg.cs_warehouse_sk = sm.sm_ship_mode_sk   -- uses the same ship mode key for both catalog and web sales (allowed by join rule)
JOIN warehouse w
  ON cs_avg.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_item_sk = i.i_item_sk
     AND ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
     AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
  ON wr.wr_order_number = cs_avg.cs_order_number
     AND wr.wr_item_sk = i.i_item_sk
     AND wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN date_dim d_open
  ON we.web_open_date_sk = d_open.d_date_sk
WHERE d.d_year = 2001
  AND w.w_country = 'United States'
  AND i.i_brand_id IN (1, 2, 3)
ORDER BY cs_avg.cs_net_profit DESC
LIMIT 100
