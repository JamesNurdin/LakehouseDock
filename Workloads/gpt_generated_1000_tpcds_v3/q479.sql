WITH store_ret AS (
    SELECT
        sr_returned_date_sk,
        sr_return_amt_inc_tax,
        sr_customer_sk,
        sr_cdemo_sk,
        sr_addr_sk,
        sr_reason_sk
    FROM store_returns
),
catalog_ret AS (
    SELECT
        cr_returned_date_sk,
        cr_return_amount,
        cr_returning_customer_sk,
        cr_returning_cdemo_sk,
        cr_returning_addr_sk,
        cr_reason_sk
    FROM catalog_returns
),
web_ret AS (
    SELECT
        wr_returned_date_sk,
        wr_return_amt_inc_tax,
        wr_refunded_customer_sk,
        wr_refunded_cdemo_sk,
        wr_refunded_addr_sk,
        wr_reason_sk
    FROM web_returns
)
SELECT
    r_store.r_reason_desc AS store_reason,
    cd_store.cd_gender AS customer_gender,
    CASE
        WHEN SUM(sr.sr_return_amt_inc_tax) > 1000 THEN 'High'
        WHEN SUM(sr.sr_return_amt_inc_tax) > 500 THEN 'Medium'
        ELSE 'Low'
    END AS store_return_category,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_inc_tax,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_inc_tax,
    COUNT(*) AS total_records,
    (SELECT AVG(sr_sub.sr_return_amt_inc_tax) FROM store_returns sr_sub) AS avg_store_return_amt_inc_tax
FROM store_ret sr
JOIN customer c_store ON sr.sr_customer_sk = c_store.c_customer_sk
JOIN customer_demographics cd_store ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
JOIN customer_address ca_store ON sr.sr_addr_sk = ca_store.ca_address_sk
JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN catalog_ret cr ON cr.cr_returning_customer_sk = c_store.c_customer_sk
JOIN customer c_catalog ON cr.cr_returning_customer_sk = c_catalog.c_customer_sk
JOIN customer_demographics cd_catalog ON cr.cr_returning_cdemo_sk = cd_catalog.cd_demo_sk
JOIN customer_address ca_catalog ON cr.cr_returning_addr_sk = ca_catalog.ca_address_sk
JOIN reason r_catalog ON cr.cr_reason_sk = r_catalog.r_reason_sk
JOIN web_ret wr ON wr.wr_refunded_customer_sk = c_store.c_customer_sk
JOIN customer c_web ON wr.wr_refunded_customer_sk = c_web.c_customer_sk
JOIN customer_demographics cd_web ON wr.wr_refunded_cdemo_sk = cd_web.cd_demo_sk
JOIN customer_address ca_web ON wr.wr_refunded_addr_sk = ca_web.ca_address_sk
JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
WHERE c_store.c_current_cdemo_sk = cd_store.cd_demo_sk
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_return_amount > 500
          AND cr2.cr_returning_customer_sk = c_store.c_customer_sk
    )
GROUP BY
    r_store.r_reason_desc,
    cd_store.cd_gender
ORDER BY total_store_return_inc_tax DESC
LIMIT 100
