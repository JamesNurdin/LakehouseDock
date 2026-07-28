WITH store_filtered AS (
    SELECT s_store_sk,
           s_store_name,
           s_state,
           s_tax_percentage,
           s_zip
    FROM store
    WHERE s_state IN ('CA', 'TX', 'NY', 'FL', 'WA')
      AND s_tax_percentage BETWEEN 0.06 AND 0.10
      AND s_zip LIKE '1%'
)
SELECT
    s.s_store_name,
    td.t_shift,
    cd_sr.cd_gender,
    hd_sr.hd_buy_potential,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_web_profit,
    RANK() OVER (PARTITION BY s.s_state ORDER BY SUM(sr.sr_return_amt) DESC) AS return_rank_by_state,
    ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS overall_profit_rank
FROM store_returns sr
JOIN store_filtered s
    ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim td
    ON sr.sr_return_time_sk = td.t_time_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd_ws
    ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN household_demographics hd_ws
    ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
WHERE cd_sr.cd_marital_status = 'M'                                 -- predicate 1
  AND cd_ws.cd_education_status = 'College'                         -- predicate 2
  AND hd_sr.hd_vehicle_count >= 2                                   -- predicate 3
  AND hd_ws.hd_income_band_sk IN (1, 2, 3)                           -- predicate 4
  AND td.t_hour BETWEEN 9 AND 17                                     -- predicate 5
  AND sr.sr_return_quantity > 1                                      -- predicate 6
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = sr.sr_customer_sk
          AND ws2.ws_net_profit > 1000
          AND ws2.ws_sold_date_sk = sr.sr_returned_date_sk
    )
GROUP BY
    s.s_store_name,
    td.t_shift,
    cd_sr.cd_gender,
    hd_sr.hd_buy_potential,
    s.s_state
ORDER BY total_return_amount DESC
LIMIT 100
