WITH unified_returns AS (
    SELECT
        cr.cr_returned_date_sk      AS returned_date_sk,
        cr.cr_refunded_customer_sk  AS customer_sk,
        cr.cr_refunded_hdemo_sk     AS hd_demo_sk,
        cr.cr_net_loss              AS net_loss,
        cr.cr_refunded_cash         AS refunded_cash,
        cr.cr_return_quantity       AS return_quantity,
        'catalog'                    AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_hdemo_sk,
        sr.sr_net_loss,
        sr.sr_refunded_cash,
        sr.sr_return_quantity,
        'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_net_loss,
        wr.wr_refunded_cash,
        wr.wr_return_quantity,
        'web' AS channel
    FROM web_returns wr
)
SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT c.c_customer_sk)                AS distinct_customers,
    SUM(ur.net_loss)                               AS total_net_loss,
    SUM(ur.refunded_cash)                          AS total_refunded_cash,
    AVG(ur.return_quantity)                       AS avg_return_quantity
FROM unified_returns ur
JOIN customer c ON ur.customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ur.hd_demo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ur.returned_date_sk BETWEEN 2450000 AND 2452000
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY total_net_loss DESC
LIMIT 100
