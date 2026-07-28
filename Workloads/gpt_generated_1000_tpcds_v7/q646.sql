WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 50
      AND cr.cr_return_quantity >= 1
), joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        r.r_reason_id,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        hd.hd_vehicle_count,
        fr.cr_return_quantity,
        fr.cr_return_amount,
        fr.cr_net_loss
    FROM filtered_returns fr
    JOIN date_dim d
      ON fr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
      ON fr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
      ON fr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND r.r_reason_id IN ('AAAAAAAAABBAAAAAA', 'AAAAAAAAANAAAAAAA')
      AND c.c_preferred_cust_flag = 'Y'
      AND hd.hd_vehicle_count >= 2
)
SELECT
    d_year,
    d_month_seq,
    r_reason_desc,
    c_customer_id,
    hd_vehicle_count,
    cr_return_quantity,
    cr_return_amount,
    cr_net_loss,
    CASE WHEN cr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    RANK() OVER (PARTITION BY r_reason_desc ORDER BY cr_return_amount DESC) AS amount_rank,
    SUM(cr_return_amount) OVER (PARTITION BY d_year ORDER BY d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_month_amount
FROM joined_data
ORDER BY d_year, d_month_seq, amount_rank
