WITH base AS (
    SELECT 
        cr.cr_returned_time_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_store_credit
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 500
      AND cr.cr_store_credit < 600
)
SELECT
    td.t_hour,
    ca.ca_county,
    r.r_reason_desc,
    COUNT(*) AS return_count,
    SUM(base.cr_return_amount) AS total_return_amount,
    AVG(base.cr_store_credit) AS avg_store_credit,
    MIN(base.cr_return_quantity) AS min_return_qty,
    MAX(base.cr_return_quantity) AS max_return_qty,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
FROM base
JOIN time_dim td
    ON base.cr_returned_time_sk = td.t_time_sk
JOIN customer_address ca
    ON base.cr_refunded_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON base.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN reason r
    ON base.cr_reason_sk = r.r_reason_sk
WHERE td.t_second IN (8, 13, 18)
  AND td.t_time BETWEEN 5 AND 12
  AND ca.ca_county IN ('Barry County', 'Madison County')
  AND ca.ca_gmt_offset = -5.00
GROUP BY td.t_hour, ca.ca_county, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
