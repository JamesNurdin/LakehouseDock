WITH filtered_catalog AS (
    SELECT cr_returned_time_sk,
           cr_reason_sk,
           cr_return_amount,
           cr_return_quantity,
           cr_order_number,
           cr_net_loss,
           cr_reversed_charge
    FROM catalog_returns
    WHERE cr_return_amount > 100.00
      AND cr_net_loss BETWEEN 50 AND 5000
      AND cr_reversed_charge < 150.00
),
filtered_store AS (
    SELECT sr_return_time_sk,
           sr_reason_sk,
           sr_return_amt,
           sr_refunded_cash,
           sr_return_quantity,
           sr_reversed_charge
    FROM store_returns
    WHERE sr_refunded_cash < 500.00
      AND sr_return_quantity >= 2
      AND sr_reversed_charge < 100.00
),
distinct_reasons AS (
    SELECT DISTINCT r_reason_sk,
           r_reason_desc,
           r_reason_id
    FROM reason
    WHERE r_reason_desc LIKE '%color%' OR r_reason_desc LIKE '%gift%'
)
SELECT
    dr.r_reason_desc,
    td.t_hour,
    COUNT(DISTINCT fc.cr_order_number) AS distinct_catalog_orders,
    SUM(fc.cr_return_amount) AS total_catalog_return_amount,
    SUM(fs.sr_return_amt) AS total_store_return_amount,
    SUM(fc.cr_return_amount) + SUM(fs.sr_return_amt) AS total_return_amount,
    AVG(fc.cr_return_quantity) AS avg_catalog_quantity,
    SUM(CASE WHEN fc.cr_return_quantity > 5 THEN fc.cr_return_amount ELSE 0 END) AS high_qty_return_amount,
    CASE
        WHEN SUM(fc.cr_return_amount) > 5000 THEN 'High'
        WHEN SUM(fc.cr_return_amount) BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS catalog_return_category
FROM filtered_catalog fc
INNER JOIN time_dim td
    ON fc.cr_returned_time_sk = td.t_time_sk
INNER JOIN distinct_reasons dr
    ON fc.cr_reason_sk = dr.r_reason_sk
INNER JOIN filtered_store fs
    ON fs.sr_return_time_sk = td.t_time_sk
   AND fs.sr_reason_sk = dr.r_reason_sk
WHERE td.t_hour BETWEEN 9 AND 17
GROUP BY dr.r_reason_desc, td.t_hour
HAVING SUM(fc.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
