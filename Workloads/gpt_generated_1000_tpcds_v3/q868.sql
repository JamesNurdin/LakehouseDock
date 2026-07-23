WITH agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        w.w_warehouse_name AS warehouse_name,
        ib.ib_income_band_sk AS income_band_sk,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_wholesale_cost > 10
      AND cs.cs_ext_sales_price > 1000
      AND hd.hd_dep_count >= 1
      AND hd.hd_vehicle_count >= 0
      AND inv.inv_quantity_on_hand > 0
      AND ss.ss_net_paid_inc_tax > 500
    GROUP BY w.w_warehouse_id,
             w.w_warehouse_name,
             ib.ib_income_band_sk,
             ib.ib_lower_bound,
             ib.ib_upper_bound
)
SELECT
    warehouse_id,
    warehouse_name,
    income_band_sk,
    lower_bound,
    upper_bound,
    total_net_profit,
    total_sales,
    avg_inventory_on_hand,
    order_cnt,
    CASE WHEN total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY income_band_sk ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY income_band_sk, profit_rank
LIMIT 100
