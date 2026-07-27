WITH cat AS (
    SELECT
        cr_refunded_customer_sk AS cust_sk,
        cr_ship_mode_sk,
        cr_reason_sk AS reason_sk,
        cr_net_loss,
        cr_return_amount,
        cr_return_quantity,
        cr_returned_date_sk
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2451860 AND 2452100
      AND cr_refunded_customer_sk IN (6114601, 1555764, 3312919)
      AND cr_reason_sk = 5
      AND cr_ship_mode_sk = 3
),
store AS (
    SELECT
        sr_customer_sk AS cust_sk,
        sr_reason_sk AS reason_sk,
        sr_net_loss,
        sr_return_amt,
        sr_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk = 2452085
      AND sr_reason_sk = 24
      AND sr_return_quantity > 0
      AND sr_return_amt > 10
)
SELECT
    c.c_customer_id,
    sm.sm_type,
    r_cat.r_reason_desc AS catalog_reason,
    r_store.r_reason_desc AS store_reason,
    SUM(cat.cr_return_amount) AS total_catalog_return_amount,
    SUM(store.sr_return_amt) AS total_store_return_amount,
    SUM(cat.cr_net_loss + store.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cat.cr_returned_date_sk) AS catalog_return_days,
    CASE
        WHEN SUM(cat.cr_net_loss + store.sr_net_loss) > 1000 THEN 'HIGH'
        ELSE 'LOW'
    END AS loss_category
FROM cat
JOIN customer c ON cat.cust_sk = c.c_customer_sk
JOIN ship_mode sm ON cat.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r_cat ON cat.reason_sk = r_cat.r_reason_sk
JOIN store ON store.cust_sk = c.c_customer_sk
JOIN reason r_store ON store.reason_sk = r_store.r_reason_sk
WHERE c.c_birth_year = 1980
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    c.c_customer_id,
    sm.sm_type,
    r_cat.r_reason_desc,
    r_store.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
