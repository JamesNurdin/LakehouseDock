WITH combined_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_sk,
        r.r_reason_desc,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        COUNT(*) AS total_rows
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt > 100.00
      AND sr.sr_return_ship_cost BETWEEN 20 AND 500
      AND wr.wr_return_amt > 50.00
      AND wr.wr_return_tax > 5.00
      AND ib.ib_lower_bound >= 50000
      AND ib.ib_upper_bound <= 150000
      AND c.c_preferred_cust_flag = 'Y'
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_sk,
        r.r_reason_desc,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    cr.ib_income_band_sk,
    cr.ib_lower_bound,
    cr.ib_upper_bound,
    AVG(cr.store_net_loss + cr.web_net_loss) AS avg_total_net_loss,
    SUM(cr.store_return_qty + cr.web_return_qty) AS total_return_qty,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper_bound
FROM combined_returns cr
GROUP BY
    cr.ib_income_band_sk,
    cr.ib_lower_bound,
    cr.ib_upper_bound
HAVING AVG(cr.store_net_loss + cr.web_net_loss) > 200.00
ORDER BY avg_total_net_loss DESC
LIMIT 100
