WITH sales_returns_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        sm.sm_type AS ship_type,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(sr.sr_fee) AS total_fees,
        CASE
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE'
            ELSE 'NON_POSITIVE'
        END AS profit_flag
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cs.cs_quantity > 1
      AND sr.sr_return_quantity > 0
      AND ib.ib_lower_bound >= 5000
      AND r.r_reason_id LIKE 'AAAA%'
    GROUP BY
        w.w_warehouse_name,
        sm.sm_type,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc
)
SELECT
    agg.warehouse_name,
    agg.ship_type,
    CONCAT(CAST(agg.ib_lower_bound AS VARCHAR), '-', CAST(agg.ib_upper_bound AS VARCHAR)) AS income_band_range,
    agg.order_cnt,
    agg.total_sales,
    agg.total_profit,
    agg.total_returns,
    agg.profit_flag,
    CASE
        WHEN agg.total_profit > (SELECT AVG(total_profit) FROM sales_returns_agg) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_vs_avg
FROM sales_returns_agg agg
WHERE agg.total_sales > 10000
  AND agg.total_returns < 5000
  AND agg.profit_flag = 'POSITIVE'
ORDER BY agg.total_profit DESC
LIMIT 100
