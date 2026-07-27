WITH sr_agg AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_store_return,
        COUNT(*) AS cnt_store_returns
    FROM store_returns sr
    WHERE sr.sr_return_time_sk IN (33881, 54713, 41472)
      AND sr.sr_return_quantity > 1
    GROUP BY sr.sr_customer_sk, sr.sr_store_sk
)
SELECT
    c.c_customer_id,
    s.s_store_name,
    sr_agg.total_store_return,
    sr_agg.cnt_store_returns,
    cr_agg.total_catalog_return,
    cr_agg.return_cnt
FROM sr_agg
JOIN customer c
    ON sr_agg.sr_customer_sk = c.c_customer_sk
JOIN store s
    ON sr_agg.sr_store_sk = s.s_store_sk
JOIN (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_call_center_sk AS call_center_sk,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 2
      AND cr.cr_return_amount > 20
    GROUP BY cr.cr_refunded_customer_sk, cr.cr_call_center_sk
) cr_agg
    ON cr_agg.customer_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM call_center cc
    WHERE cc.cc_call_center_sk = cr_agg.call_center_sk
      AND cc.cc_division = 1
      AND cc.cc_mkt_desc LIKE '%Blue%'
)
  AND s.s_state = 'CA'
  AND c.c_birth_country = 'United States'
LIMIT 100
