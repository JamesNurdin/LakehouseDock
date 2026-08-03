WITH returns_with_details AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        i.i_item_desc,
        i.i_brand,
        c.c_email_address,
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(i.i_item_desc, '(?i)TV|PHONE')
      AND c.c_email_address LIKE '%@example.com'
)
SELECT
    CONCAT(i_brand, ' - ', SUBSTRING(i_item_desc, 1, 20)) AS brand_desc,
    r_reason_desc,
    d_year,
    d_month_seq,
    COUNT(*) AS return_cnt,
    SUM(sr_return_amt) AS total_return_amount,
    REGEXP_EXTRACT(i_item_desc, '([A-Z]{3}[0-9]{2})') AS extracted_code
FROM returns_with_details rwd
WHERE NOT EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_item_sk = rwd.sr_item_sk
      AND p.p_start_date_sk <= rwd.sr_returned_date_sk
      AND p.p_end_date_sk >= rwd.sr_returned_date_sk
      AND p.p_discount_active = 'Y'
)
GROUP BY
    CONCAT(i_brand, ' - ', SUBSTRING(i_item_desc, 1, 20)),
    r_reason_desc,
    d_year,
    d_month_seq,
    REGEXP_EXTRACT(i_item_desc, '([A-Z]{3}[0-9]{2})')
ORDER BY total_return_amount DESC
LIMIT 100
