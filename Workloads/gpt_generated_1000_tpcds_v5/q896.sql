WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_hdemo_sk,
        ss_ticket_number,
        SUM(ss_ext_sales_price) AS total_sales_price,
        SUM(ss_ext_discount_amt) AS total_discount,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    WHERE ss_ext_sales_price > 500
    GROUP BY ss_item_sk, ss_hdemo_sk, ss_ticket_number
),
filtered_reasons AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%price%'
)
SELECT
    ib_ss.ib_upper_bound AS store_income_upper,
    ib_wr.ib_upper_bound AS web_income_upper,
    r_sr.r_reason_desc AS store_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(ss_agg.total_sales_price) AS total_sales_price,
    SUM(ss_agg.total_net_profit) AS total_sales_net_profit,
    (
        SELECT AVG(s2.total_discount)
        FROM ss_agg s2
        WHERE s2.ss_hdemo_sk = hd_ss.hd_demo_sk
    ) AS avg_discount_per_income_band
FROM store_returns sr
JOIN ss_agg
    ON sr.sr_item_sk = ss_agg.ss_item_sk
    AND sr.sr_ticket_number = ss_agg.ss_ticket_number
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN income_band ib_sr
    ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
JOIN filtered_reasons r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN household_demographics hd_ss
    ON ss_agg.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN income_band ib_ss
    ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
JOIN web_returns wr
    ON wr.wr_refunded_hdemo_sk = hd_sr.hd_demo_sk
JOIN household_demographics hd_wr_ret
    ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
JOIN income_band ib_wr
    ON hd_wr_ret.hd_income_band_sk = ib_wr.ib_income_band_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
GROUP BY
    ib_ss.ib_upper_bound,
    ib_wr.ib_upper_bound,
    r_sr.r_reason_desc,
    r_wr.r_reason_desc,
    hd_ss.hd_demo_sk
ORDER BY total_store_return_loss DESC
LIMIT 100
