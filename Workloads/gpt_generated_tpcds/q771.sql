WITH sales AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ss.ss_net_profit AS profit,
        CAST(NULL AS decimal(7,2)) AS loss
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk

    UNION ALL

    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        cs.cs_net_profit,
        CAST(NULL AS decimal(7,2))
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk

    UNION ALL

    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ws.ws_net_profit,
        CAST(NULL AS decimal(7,2))
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
), returns AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        CAST(NULL AS decimal(7,2)) AS profit,
        sr.sr_net_loss AS loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk

    UNION ALL

    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        CAST(NULL AS decimal(7,2)),
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
), combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    c.hd_buy_potential,
    SUM(c.profit) AS total_sales_profit,
    SUM(c.loss)   AS total_return_loss,
    SUM(c.profit) - SUM(c.loss) AS net_profit
FROM combined c
JOIN income_band ib
  ON c.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    c.hd_buy_potential
ORDER BY net_profit DESC
LIMIT 10
