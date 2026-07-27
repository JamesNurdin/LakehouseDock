WITH filtered AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_hdemo_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        d.d_year,
        c.c_customer_id,
        c.c_email_address,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        cc.cc_name,
        cr.cr_return_amount
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = sr.sr_returned_date_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND sr.sr_return_amt > 50
      AND hd.hd_buy_potential = '5001-10000'
      AND r.r_reason_desc IN ('Damaged', 'Defective')
      AND EXISTS (
            SELECT 1
            FROM warehouse w
            WHERE w.w_warehouse_sk = cr.cr_warehouse_sk
              AND w.w_city = 'Seattle'
      )
)
SELECT
    f.c_customer_id,
    f.d_year,
    f.cc_name,
    f.r_reason_desc,
    SUM(f.sr_return_amt) AS total_return_amt,
    SUM(f.sr_return_tax) AS total_return_tax,
    COUNT(*) AS return_cnt,
    RANK() OVER (PARTITION BY f.c_customer_id ORDER BY SUM(f.sr_return_amt) DESC) AS rank_per_customer,
    ROW_NUMBER() OVER (PARTITION BY f.d_year ORDER BY SUM(f.sr_return_amt) DESC) AS yearly_row_num,
    (SELECT AVG(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_returned_date_sk = f.sr_returned_date_sk) AS avg_catalog_return_amt
FROM filtered f
GROUP BY
    f.c_customer_id,
    f.d_year,
    f.cc_name,
    f.r_reason_desc,
    f.sr_returned_date_sk
HAVING COUNT(*) >= 5
ORDER BY total_return_amt DESC
LIMIT 100
