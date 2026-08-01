WITH joined AS (
    SELECT
        r.r_reason_desc,
        ca.ca_state,
        cd.cd_gender,
        cr.cr_return_amount,
        cr.cr_fee,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE sr.sr_store_sk IN (500, 298, 962)
      AND cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 50
      AND wr.wr_fee > 20
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
),
agg AS (
    SELECT
        r_reason_desc,
        ca_state,
        cd_gender,
        SUM(cr_return_amount) AS total_refund_amount,
        SUM(cr_fee) AS total_refund_fee,
        SUM(sr_return_amt_inc_tax) AS total_store_return_inc_tax,
        SUM(sr_fee) AS total_store_fee,
        SUM(wr_return_amt_inc_tax) AS total_web_return_inc_tax,
        SUM(wr_fee) AS total_web_fee
    FROM joined
    GROUP BY r_reason_desc, ca_state, cd_gender
    HAVING SUM(cr_return_amount) > 100
       AND COUNT(*) >= 5
)
SELECT
    r_reason_desc,
    ca_state,
    cd_gender,
    total_refund_amount,
    total_refund_fee,
    total_store_return_inc_tax,
    total_store_fee,
    total_web_return_inc_tax,
    total_web_fee,
    (total_refund_amount + total_store_return_inc_tax + total_web_return_inc_tax) AS total_return_inc_tax,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY (total_refund_amount + total_store_return_inc_tax + total_web_return_inc_tax) DESC) AS rn_state,
    RANK() OVER (PARTITION BY ca_state ORDER BY (total_refund_amount + total_store_return_inc_tax + total_web_return_inc_tax) DESC) AS rank_state
FROM agg
ORDER BY total_return_inc_tax DESC
LIMIT 100
