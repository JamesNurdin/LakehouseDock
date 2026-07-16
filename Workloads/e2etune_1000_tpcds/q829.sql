WITH store_perf AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        COUNT(DISTINCT hd.hd_demo_sk) AS household_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_state = 'CA'
      AND hd.hd_buy_potential IN ('1001-5000', '5001-10000', '>10000')
      AND ib.ib_lower_bound >= 50000
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY s.s_store_id, s.s_store_name, s.s_state
)
SELECT *
FROM (
    SELECT
        sp.s_store_id,
        sp.s_store_name,
        sp.s_state,
        sp.total_net_profit,
        sp.total_sales,
        sp.avg_discount,
        sp.avg_vehicle_count,
        sp.household_count,
        ROW_NUMBER() OVER (ORDER BY sp.total_net_profit DESC) AS profit_rank
    FROM store_perf sp
) ranked
WHERE profit_rank <= 10
ORDER BY profit_rank
