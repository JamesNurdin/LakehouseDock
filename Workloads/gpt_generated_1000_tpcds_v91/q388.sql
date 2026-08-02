WITH cr AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ca.ca_state,
        ca.ca_zip,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(?i)(damaged|broken)', 1) AS extracted_reason,
        d.d_date,
        t.t_meal_time,
        concat(ca.ca_city, ', ', ca.ca_state) AS city_state,
        substr(ca.ca_zip, 1, 5) AS zip_prefix
    FROM catalog_returns cr
    LEFT JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damaged')
      AND ca.ca_state LIKE 'A%'
),
wr AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        ca.ca_state,
        ca.ca_zip,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(?i)(defective|broken)', 1) AS extracted_reason,
        d.d_date,
        t.t_meal_time,
        concat(ca.ca_city, ', ', ca.ca_state) AS city_state,
        substr(ca.ca_zip, 1, 5) AS zip_prefix
    FROM web_returns wr
    LEFT JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)defective')
      AND ca.ca_zip LIKE '9%'
)
SELECT
    COALESCE(cr.d_date, wr.d_date) AS return_date,
    COALESCE(cr.zip_prefix, wr.zip_prefix) AS zip_prefix,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amount,
    SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    COALESCE(cr.city_state, wr.city_state) AS city_state,
    COALESCE(cr.r_reason_desc, wr.r_reason_desc) AS reason_desc,
    COALESCE(cr.extracted_reason, wr.extracted_reason) AS extracted_reason
FROM cr
FULL OUTER JOIN wr
    ON cr.d_date = wr.d_date
   AND cr.zip_prefix = wr.zip_prefix
GROUP BY
    COALESCE(cr.d_date, wr.d_date),
    COALESCE(cr.zip_prefix, wr.zip_prefix),
    COALESCE(cr.city_state, wr.city_state),
    COALESCE(cr.r_reason_desc, wr.r_reason_desc),
    COALESCE(cr.extracted_reason, wr.extracted_reason)
ORDER BY
    return_date DESC,
    zip_prefix
LIMIT 100
