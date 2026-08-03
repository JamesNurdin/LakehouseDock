/* goal: Identify the top‑selling items (by combined catalog and store net profit) for the year 2001, focusing on large call centers and warehouses in Salem, and rank them while comparing each item's total profit to the overall maximum catalog net paid amount */
WITH max_catalog_paid AS (
    SELECT MAX(cs_net_paid) AS max_paid
    FROM catalog_sales
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ss.ss_net_profit) AS store_profit,
    (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit)) AS total_profit,
    RANK() OVER (ORDER BY (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit)) DESC) AS profit_rank,
    CASE
        WHEN (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit)) > (
            SELECT AVG(tp.avg_total_profit)
            FROM (
                SELECT (SUM(cs2.cs_net_profit) + SUM(ss2.ss_net_profit)) AS avg_total_profit
                FROM catalog_sales cs2
                JOIN store_sales ss2 ON ss2.ss_item_sk = cs2.cs_item_sk
                GROUP BY cs2.cs_item_sk
            ) tp
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    CASE
        WHEN (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit)) > (SELECT max_paid FROM max_catalog_paid) THEN 'Exceeds Max'
        ELSE 'Below Max'
    END AS max_comparison
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
WHERE d_sold.d_year = 2001
  AND cc.cc_class = 'large'
  AND w.w_city = 'Salem'
GROUP BY i.i_item_id, i.i_item_desc
ORDER BY total_profit DESC
LIMIT 100
