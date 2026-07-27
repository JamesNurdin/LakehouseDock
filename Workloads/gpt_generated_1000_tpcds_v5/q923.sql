WITH sr_agg AS (
    SELECT
        sr_cdemo_sk,
        sr_hdemo_sk,
        sr_addr_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    WHERE sr_return_amt > 0
      AND sr_store_credit > 10
      AND sr_return_ship_cost BETWEEN 50 AND 2000
      AND sr_return_quantity >= 1
      AND sr_fee < 500
      AND sr_refunded_cash >= 0
    GROUP BY sr_cdemo_sk, sr_hdemo_sk, sr_addr_sk
),
ws_agg AS (
    SELECT
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_web_site_sk,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_quantity > 0
      AND ws_net_paid > 0
      AND ws_ext_discount_amt < 1000
      AND ws_ship_mode_sk IS NOT NULL
      AND ws_promo_sk IS NOT NULL
      AND ws_coupon_amt >= 0
    GROUP BY ws_bill_cdemo_sk, ws_bill_hdemo_sk, ws_bill_addr_sk, ws_web_site_sk
)
SELECT
    ca.ca_state,
    ca.ca_country,
    cd.cd_gender,
    cd.cd_education_status,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ws.total_net_paid,
    ws.total_net_profit,
    sr.total_return_amt,
    sr.return_cnt,
    ws.sales_cnt,
    (sr.total_return_amt / NULLIF(ws.total_net_paid, 0)) AS return_to_sales_ratio,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ws.total_net_paid DESC) AS state_sales_rank
FROM sr_agg sr
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ws_agg ws
    ON sr.sr_cdemo_sk = ws.ws_bill_cdemo_sk
   AND sr.sr_hdemo_sk = ws.ws_bill_hdemo_sk
   AND sr.sr_addr_sk = ws.ws_bill_addr_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_country = 'United States'
  AND cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'M'
  AND hd.hd_vehicle_count >= 0
  AND ib.ib_upper_bound >= 50000
ORDER BY return_to_sales_ratio DESC
LIMIT 100
