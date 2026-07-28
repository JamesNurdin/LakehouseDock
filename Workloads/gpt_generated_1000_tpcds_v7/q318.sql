WITH joined_data AS (
    SELECT
        sr.sr_reason_sk AS sr_reason_sk,
        r.r_reason_desc AS r_reason_desc,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_return_amt AS sr_return_amt,
        sr.sr_net_loss AS sr_net_loss,
        cc.cc_mkt_id AS cc_mkt_id,
        w.w_country AS w_country,
        t.t_hour AS t_hour,
        c.c_birth_year AS c_birth_year,
        sr.sr_return_quantity AS sr_return_quantity
    FROM store_returns sr
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
      ON t.t_time_sk = cr.cr_returned_time_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_mkt_id IN (1, 2)
      AND w.w_country = 'United States'
      AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
      AND t.t_hour BETWEEN 9 AND 17
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND sr.sr_return_quantity > 1
      AND cc.cc_rec_start_date > DATE '2000-01-01'
),
per_reason AS (
    SELECT
        sr_reason_sk,
        r_reason_desc,
        COUNT(*) AS cnt_returns,
        SUM(sr_return_amt) AS sum_store_return,
        SUM(sr_net_loss) AS sum_store_loss,
        SUM(cr_return_amount) AS sum_catalog_return,
        SUM(cr_net_loss) AS sum_catalog_loss
    FROM joined_data
    GROUP BY sr_reason_sk, r_reason_desc
)
SELECT
    sr_reason_sk,
    r_reason_desc,
    cnt_returns,
    sum_store_return,
    sum_catalog_return,
    (sum_store_loss + sum_catalog_loss) / NULLIF(cnt_returns, 0) AS avg_total_loss_per_return
FROM per_reason
WHERE cnt_returns >= 10
ORDER BY avg_total_loss_per_return DESC
LIMIT 10
