WITH ss_with_avg AS (
    SELECT
        ss.*,
        (SELECT AVG(ss2.ss_ext_discount_amt)
         FROM store_sales ss2
         WHERE ss2.ss_hdemo_sk = ss.ss_hdemo_sk) AS avg_discount_hdemo
    FROM store_sales ss
)
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss_with_avg.ss_sold_date_sk,
    ss_with_avg.ss_ext_sales_price,
    ss_with_avg.ss_net_profit,
    COALESCE(ws.ws_order_number, -1) AS ws_order_number,
    ss_with_avg.avg_discount_hdemo,
    ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY ss_with_avg.ss_net_profit DESC) AS profit_rank,
    CASE
        WHEN ss_with_avg.ss_net_profit > 10000 THEN 'HIGH'
        WHEN ss_with_avg.ss_net_profit > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM ss_with_avg
JOIN customer_demographics cd
    ON ss_with_avg.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss_with_avg.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE ss_with_avg.ss_ext_wholesale_cost > 5000
  AND ss_with_avg.ss_ext_discount_amt BETWEEN 100 AND 2000
  AND ib.ib_upper_bound >= 50000
  AND cd.cd_gender = 'F'
  AND cd.cd_credit_rating = 'A'
  AND hd.hd_vehicle_count >= 2
  AND (ws.ws_quantity > 0 OR ws.ws_quantity IS NULL)
ORDER BY ib.ib_income_band_sk, profit_rank
LIMIT 100
