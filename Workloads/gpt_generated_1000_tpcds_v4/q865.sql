WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_net_paid) AS total_net_paid_cs,
        COUNT(*) AS cnt_cs
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND hd_bill.hd_buy_potential = 'HIGH'
    GROUP BY cs.cs_sold_date_sk, cs.cs_call_center_sk, cs.cs_ship_mode_sk,
             cs.cs_bill_hdemo_sk, cs.cs_ship_hdemo_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_paid) AS ws_total
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2001
    GROUP BY ws.ws_sold_date_sk, ws.ws_ship_mode_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_hdemo_sk,
        SUM(sr.sr_net_loss) AS sr_total_loss
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    WHERE d_sr.d_year = 2001
      AND sr.sr_net_loss > 500
    GROUP BY sr.sr_returned_date_sk, sr.sr_hdemo_sk
)
SELECT DISTINCT
    cc.cc_name,
    sm.sm_type,
    ib.ib_income_band_sk,
    d.d_month_seq,
    SUM(sa.total_net_paid_cs) AS total_net_paid_catalog,
    COALESCE(SUM(ws.ws_total), 0) AS total_net_paid_web,
    COALESCE(SUM(sr.sr_total_loss), 0) AS total_net_loss_returns,
    COUNT(*) AS record_count
FROM sales_agg sa
JOIN call_center cc ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d ON sa.cs_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_sales_agg ws
       ON ws.ws_sold_date_sk = sa.cs_sold_date_sk
      AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN store_returns_agg sr
       ON sr.sr_returned_date_sk = sa.cs_sold_date_sk
      AND sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND sr2.sr_net_loss > 1000
      AND sr2.sr_hdemo_sk = hd.hd_demo_sk
)
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND ib.ib_upper_bound <= 90000
  AND cc.cc_gmt_offset BETWEEN -5 AND 5
  AND sm.sm_code = 'SM01'
GROUP BY cc.cc_name, sm.sm_type, ib.ib_income_band_sk, d.d_month_seq
ORDER BY total_net_paid_catalog DESC
LIMIT 100
