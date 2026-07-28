WITH joined_agg1 AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_bucket,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
      AND cs.cs_net_profit > 0
      AND hd.hd_buy_potential = '1001-5000'
      AND ib.ib_upper_bound <= 100000
      AND w.w_warehouse_sq_ft > 15000
    GROUP BY d.d_year,
             i.i_category,
             CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END
),
joined_agg2 AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_bucket,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site ws ON ws.web_close_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
      AND i.i_category = 'Furniture'
      AND cs.cs_net_profit < 0
      AND hd.hd_buy_potential = '0-500'
      AND ib.ib_lower_bound >= 90001
      AND w.w_warehouse_sq_ft BETWEEN 20000 AND 50000
    GROUP BY d.d_year,
             i.i_category,
             CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END
)
SELECT
    year,
    category,
    qty_bucket,
    SUM(total_net_profit) AS sum_net_profit,
    SUM(total_sales) AS sum_sales,
    SUM(txn_cnt) AS total_transactions
FROM (
    SELECT * FROM joined_agg1
    UNION ALL
    SELECT * FROM joined_agg2
) u
GROUP BY ROLLUP (year, category, qty_bucket)
HAVING SUM(total_net_profit) > 5000
ORDER BY year, category, qty_bucket
LIMIT 100
