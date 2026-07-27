WITH filtered_returns AS (
    SELECT
        wr.wr_reason_sk,
        reason.r_reason_desc,
        wr.wr_item_sk,
        i.i_item_desc,
        i.i_product_name,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS item_code,
        wr.wr_return_amt_inc_tax,
        c.c_email_address,
        substr(c.c_email_address, strpos(c.c_email_address, '@') + 1) AS email_domain,
        c.c_preferred_cust_flag,
        cd.cd_marital_status,
        wp.wp_type
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN reason ON wr.wr_reason_sk = reason.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}\\d{3}')
      AND c.c_email_address LIKE '%@example.com'
      AND cd.cd_marital_status = 'M'
      AND wp.wp_type = 'product'
)
SELECT
    fr.r_reason_desc,
    fr.item_code,
    COUNT(*) AS num_returns,
    SUM(fr.wr_return_amt_inc_tax) AS total_return_amount,
    AVG(fr.wr_return_amt_inc_tax) AS avg_return_amount,
    MIN(fr.email_domain) AS email_domain
FROM filtered_returns fr
WHERE fr.item_code IS NOT NULL
GROUP BY fr.r_reason_desc, fr.item_code
HAVING SUM(fr.wr_return_amt_inc_tax) > (
    SELECT AVG(wr2.wr_return_amt_inc_tax) * 5
    FROM web_returns wr2
)
ORDER BY total_return_amount DESC
LIMIT 100
