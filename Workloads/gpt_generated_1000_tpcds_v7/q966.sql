WITH cs_sales_agg AS (
    SELECT
        cs_bill_hdemo_sk AS hd_demo_sk,
        cs_ship_mode_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 2
      AND cs_sales_price > 100
    GROUP BY cs_bill_hdemo_sk, cs_ship_mode_sk
),

sr_returns_agg AS (
    SELECT
        sr_hdemo_sk AS hd_demo_sk,
        sr_reason_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
    GROUP BY sr_hdemo_sk, sr_reason_sk
),

wr_detail AS (
    SELECT
        wr_refunded_hdemo_sk AS hd_demo_sk,
        wr_web_page_sk,
        wr_reason_sk,
        SUM(wr_return_amt) AS total_wr_return_amt,
        COUNT(*) AS web_returns_cnt
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt > 0
    GROUP BY wr_refunded_hdemo_sk, wr_web_page_sk, wr_reason_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    r_sr.r_reason_desc AS store_reason,
    r_wr.r_reason_desc AS web_reason,
    wp.wp_type,
    SUM(cs.total_net_profit) AS sum_profit,
    SUM(sr.total_net_loss) AS sum_store_loss,
    SUM(wr.total_wr_return_amt) AS sum_web_return_amt,
    SUM(cs.sales_cnt) AS total_sales,
    SUM(sr.returns_cnt) AS total_store_returns,
    SUM(wr.web_returns_cnt) AS total_web_returns,
    (SUM(cs.total_net_profit) - SUM(sr.total_net_loss) - SUM(wr.total_wr_return_amt)) AS net_contribution
FROM cs_sales_agg cs
JOIN household_demographics hd ON cs.hd_demo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN sr_returns_agg sr ON sr.hd_demo_sk = hd.hd_demo_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN wr_detail wr ON wr.hd_demo_sk = hd.hd_demo_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE ib.ib_upper_bound <= 150000
  AND ib.ib_lower_bound >= 40000
  AND sm.sm_type = 'AIR'
  AND r_sr.r_reason_desc LIKE '%Lost%'
  AND wp.wp_type = 'PRODUCT'
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound,
         sm.sm_type, r_sr.r_reason_desc, r_wr.r_reason_desc, wp.wp_type
HAVING (SUM(cs.total_net_profit) - SUM(sr.total_net_loss) - SUM(wr.total_wr_return_amt)) > 0
ORDER BY net_contribution DESC
LIMIT 10
