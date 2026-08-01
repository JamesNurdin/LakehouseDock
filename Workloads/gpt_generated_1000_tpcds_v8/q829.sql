WITH
    sampled_cr AS (
        SELECT cr_refunded_customer_sk AS cust_sk,
               cr_return_amount,
               cr_return_tax,
               cr_fee
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
        WHERE cr_return_amount > 30
    ),
    sampled_sr AS (
        SELECT sr_customer_sk AS cust_sk,
               sr_return_amt,
               sr_return_tax,
               sr_fee
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)
        WHERE sr_return_amt > 30
    ),
    common_cust AS (
        SELECT cust_sk FROM sampled_cr
        INTERSECT
        SELECT cust_sk FROM sampled_sr
    ),
    full_joined AS (
        SELECT cr.cust_sk AS cr_cust,
               sr.cust_sk AS sr_cust,
               cr.cr_return_amount,
               sr.sr_return_amt,
               cr.cr_fee,
               sr.sr_fee
        FROM sampled_cr cr
        FULL OUTER JOIN sampled_sr sr
            ON cr.cust_sk = sr.cust_sk
    ),
    union_data AS (
        SELECT c.c_customer_id,
               cr.cust_sk,
               'catalog' AS src,
               cr.cr_return_amount + cr.cr_return_tax + cr.cr_fee AS total_loss
        FROM sampled_cr cr
        JOIN customer c ON cr.cust_sk = c.c_customer_sk
        WHERE cr.cust_sk NOT IN (SELECT cust_sk FROM sampled_sr)
        UNION
        SELECT c.c_customer_id,
               sr.cust_sk,
               'store' AS src,
               sr.sr_return_amt + sr.sr_return_tax + sr.sr_fee AS total_loss
        FROM sampled_sr sr
        JOIN customer c ON sr.cust_sk = c.c_customer_sk
        WHERE sr.cust_sk NOT IN (SELECT cust_sk FROM sampled_cr)
    )
SELECT ud.c_customer_id,
       ud.src,
       ud.total_loss,
       (SELECT MAX(total_loss) FROM union_data) AS max_total_loss_overall
FROM union_data ud
WHERE ud.cust_sk IN (SELECT cust_sk FROM common_cust)
  AND ud.c_customer_id IN (SELECT c_customer_id FROM customer WHERE c_birth_year = 1966)
ORDER BY ud.total_loss DESC
LIMIT 50
