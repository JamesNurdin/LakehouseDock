WITH cr_agg AS (
    SELECT
        cr_reason_sk,
        cr_returned_time_sk,
        cr_refunded_customer_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        SUM(cr_return_amount)      AS total_return_amount,
        SUM(cr_net_loss)           AS total_net_loss,
        COUNT(*)                  AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_amount > 50
    GROUP BY
        cr_reason_sk,
        cr_returned_time_sk,
        cr_refunded_customer_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk
)
SELECT
    r.r_reason_desc,
    t.t_sub_shift,
    SUM(a.total_return_amount) AS sum_return_amount,
    AVG(a.total_net_loss)       AS avg_net_loss,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(ib.ib_upper_bound)          AS total_income_upper
FROM cr_agg a
JOIN reason r
    ON a.cr_reason_sk = r.r_reason_sk
JOIN time_dim t
    ON a.cr_returned_time_sk = t.t_time_sk
JOIN customer c
    ON a.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON a.cr_refunded_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON a.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE t.t_sub_shift = 'morning'
  AND c.c_birth_year >= 1980
  AND ib.ib_lower_bound > 50000
GROUP BY r.r_reason_desc, t.t_sub_shift
ORDER BY sum_return_amount DESC
LIMIT 100
