WITH base AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        r.r_reason_desc,
        hd.hd_income_band_sk,
        sm.sm_carrier,
        w.w_state,
        sr.sr_return_amt,
        ws.ws_net_profit,
        sr.sr_return_quantity,
        ws.ws_quantity
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND r.r_reason_id LIKE 'AAAA%'
      AND sm.sm_carrier = 'GREAT EASTERN'
      AND w.w_state = 'CA'
      AND sr.sr_return_quantity > 1
      AND ws.ws_net_profit > 0
),
agg AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_education_status,
        r_reason_desc,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(ws_net_profit) AS total_profit,
        SUM(sr_return_quantity + ws_quantity) AS total_units,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY cd_demo_sk, cd_gender, cd_education_status, r_reason_desc
)
SELECT
    cd_demo_sk,
    cd_gender,
    cd_education_status,
    r_reason_desc,
    total_return_amt,
    total_profit,
    total_units,
    txn_count,
    total_profit / NULLIF(total_units, 0) AS profit_per_unit
FROM agg
WHERE total_profit > 1000
  AND total_return_amt > 500
  AND txn_count >= 5
ORDER BY profit_per_unit DESC
LIMIT 100
