WITH combined_metrics AS (
    -- Net profit from catalog sales (billing side)
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        cs.cs_net_profit AS net_amount
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Net profit from store sales
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        ss.ss_net_profit AS net_amount
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Negative impact of store returns (loss)
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        -sr.sr_net_loss AS net_amount
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Negative impact of web returns (loss)
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        -wr.wr_net_loss AS net_amount
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    SUM(net_amount) AS net_profit_combined,
    SUM(CASE WHEN net_amount >= 0 THEN net_amount ELSE 0 END) AS total_sales_net,
    SUM(CASE WHEN net_amount < 0 THEN -net_amount ELSE 0 END) AS total_returns_net
FROM combined_metrics
GROUP BY ib_lower_bound, ib_upper_bound, hd_buy_potential
ORDER BY net_profit_combined DESC
LIMIT 10
