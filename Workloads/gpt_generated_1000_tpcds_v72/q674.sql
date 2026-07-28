WITH store_loss AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 50000
      AND cd.cd_gender = 'F'
      AND sr.sr_cdemo_sk IN (
          SELECT cd_demo_sk
          FROM customer_demographics
          WHERE cd_purchase_estimate > 500
      )
    GROUP BY r.r_reason_desc
),
web_loss AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS total_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound < 20000
      AND EXISTS (
          SELECT 1
          FROM web_site wsite
          WHERE wsite.web_site_sk = ws.ws_web_site_sk
            AND wsite.web_state = 'CA'
      )
    GROUP BY r.r_reason_desc
)
SELECT reason_desc, total_loss
FROM store_loss
UNION ALL
SELECT reason_desc, total_loss
FROM web_loss
ORDER BY total_loss DESC
LIMIT 100
