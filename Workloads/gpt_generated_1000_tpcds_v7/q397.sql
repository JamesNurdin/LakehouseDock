WITH cs_agg AS (
    SELECT
        cs_bill_hdemo_sk AS hd_demo_sk,
        cs_warehouse_sk AS warehouse_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS sales_orders
    FROM catalog_sales
    WHERE cs_quantity > 1
      AND cs_ext_sales_price > 1000
    GROUP BY cs_bill_hdemo_sk, cs_warehouse_sk
),
ws_agg AS (
    SELECT
        ws_bill_hdemo_sk AS hd_demo_sk,
        ws_warehouse_sk AS warehouse_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS web_orders
    FROM web_sales
    WHERE ws_ext_list_price > 5000
    GROUP BY ws_bill_hdemo_sk, ws_warehouse_sk
),
sr_agg AS (
    SELECT
        sr_hdemo_sk AS hd_demo_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_hdemo_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_vehicle_count,
    w.w_city,
    SUM(cs_agg.total_sales) AS catalog_sales_total,
    SUM(ws_agg.total_sales) AS web_sales_total,
    SUM(sr_agg.total_return_amt) AS total_returns,
    (SUM(cs_agg.total_profit) + SUM(ws_agg.total_profit) - SUM(sr_agg.total_return_amt)) AS net_contribution,
    COUNT(DISTINCT cs_agg.sales_orders) AS distinct_catalog_orders,
    COUNT(DISTINCT ws_agg.web_orders) AS distinct_web_orders
FROM household_demographics hd
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN cs_agg
    ON cs_agg.hd_demo_sk = hd.hd_demo_sk
JOIN ws_agg
    ON ws_agg.hd_demo_sk = hd.hd_demo_sk
JOIN sr_agg
    ON sr_agg.hd_demo_sk = hd.hd_demo_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cs_agg.warehouse_sk
    AND w.w_warehouse_sk = ws_agg.warehouse_sk
WHERE hd.hd_vehicle_count = 2
  AND ib.ib_lower_bound >= 80000
  AND ib.ib_upper_bound <= 200000
  AND w.w_state = 'CA'
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_vehicle_count,
    w.w_city
HAVING SUM(cs_agg.total_profit) > (SELECT AVG(cs_net_profit) FROM catalog_sales)
ORDER BY net_contribution DESC
