WITH ws_hd AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_promo_sk,
        ws.ws_bill_hdemo_sk,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_dep_count
    FROM tpcds.web_sales ws
    JOIN tpcds.household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_promo_sk IN (871, 999)
      AND ws.ws_bill_hdemo_sk = 6410
      AND hd.hd_vehicle_count >= 2
      AND hd.hd_dep_count <= 3
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN ib.ib_upper_bound > 150000 THEN 'High Income'
        ELSE 'Mid/Low Income'
    END AS income_category,
    ws_hd.hd_buy_potential,
    COUNT(DISTINCT ws_hd.ws_order_number) AS orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(ws_hd.ws_net_profit) AS avg_net_profit,
    MIN(ws_hd.ws_net_paid) AS min_net_paid,
    MAX(ws_hd.ws_net_paid) AS max_net_paid,
    SUM(CASE WHEN wr.wr_return_quantity > 1 THEN wr.wr_return_amt ELSE 0 END) AS multi_item_return_amount
FROM ws_hd
JOIN tpcds.income_band ib
  ON ws_hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.web_returns wr
  ON wr.wr_order_number = ws_hd.ws_order_number
 AND wr.wr_item_sk = ws_hd.ws_item_sk
 AND wr.wr_refunded_hdemo_sk = ws_hd.hd_demo_sk
WHERE wr.wr_return_quantity BETWEEN 1 AND 5
  AND wr.wr_return_amt > 10
  AND ib.ib_lower_bound >= 80001
  AND ib.ib_upper_bound <= 200000
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN ib.ib_upper_bound > 150000 THEN 'High Income'
        ELSE 'Mid/Low Income'
    END,
    ws_hd.hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
