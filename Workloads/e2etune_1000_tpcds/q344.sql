WITH agg AS (
    SELECT
        i.i_category AS category,
        ib.ib_upper_bound AS income_ub,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 2
      AND hd.hd_dep_count <= 2
      AND ib.ib_upper_bound >= 30000
      AND i.i_category IS NOT NULL
      AND ss.ss_ext_discount_amt > 0
    GROUP BY i.i_category, ib.ib_upper_bound
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    category,
    income_ub,
    total_net_paid,
    total_quantity,
    avg_discount,
    total_net_profit / NULLIF(total_net_paid, 0) AS profit_margin,
    RANK() OVER (PARTITION BY income_ub ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_margin DESC
LIMIT 20
