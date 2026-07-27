WITH base AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_dep_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_ext_discount_amt,
        ws.ws_order_number,
        ws.ws_ext_ship_cost,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_order_number,
        wr.wr_return_amt,
        COALESCE(sm_cs.sm_ship_mode_id, sm_ws.sm_ship_mode_id) AS ship_mode_id,
        CASE
            WHEN COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(wr.wr_return_amt, 0) > 1000 THEN 'HIGH'
            ELSE 'LOW'
        END AS profit_level
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    WHERE hd.hd_dep_count <= 5
      AND ib.ib_upper_bound >= 80000
      AND (cs.cs_quantity > 5 OR ws.ws_ext_ship_cost > 150)
)
SELECT
    b.ib_income_band_sk,
    b.profit_level,
    COUNT(DISTINCT b.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT b.ws_order_number) AS web_order_cnt,
    SUM(COALESCE(b.cs_net_profit, 0) + COALESCE(b.ws_net_profit, 0) - COALESCE(b.wr_return_amt, 0)) AS net_profit_sum,
    AVG(COALESCE(b.cs_net_profit, 0) + COALESCE(b.ws_net_profit, 0) - COALESCE(b.wr_return_amt, 0)) AS net_profit_avg,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper,
    (SELECT COUNT(*) FROM catalog_sales WHERE cs_ext_discount_amt > 100) AS high_discount_cnt,
    CASE
        WHEN SUM(COALESCE(b.cs_net_profit, 0) + COALESCE(b.ws_net_profit, 0) - COALESCE(b.wr_return_amt, 0)) > 5000 THEN 'VERY HIGH'
        ELSE 'MODERATE'
    END AS overall_category
FROM base b
WHERE b.cs_order_number IN (
        SELECT cs_order_number FROM catalog_sales WHERE cs_ext_discount_amt > 50
        UNION
        SELECT wr_returning_hdemo_sk FROM web_returns WHERE wr_return_amt > 200
    )
GROUP BY b.ib_income_band_sk, b.profit_level
HAVING COUNT(DISTINCT b.cs_order_number) >= 10
ORDER BY net_profit_sum DESC
LIMIT 100
