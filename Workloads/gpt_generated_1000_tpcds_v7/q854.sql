WITH returns AS (
    SELECT 
        sr.sr_returned_date_sk,
        sr.sr_return_amt AS return_amt,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_customer_sk,
        sr.sr_item_sk,
        sr.sr_reason_sk,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_item_desc,
        i.i_product_name,
        r.r_reason_desc,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        regexp_extract(i.i_product_name, '(\\w+)-', 1) AS product_prefix,
        CASE 
            WHEN regexp_like(i.i_item_desc, '(?i)soft') THEN 'Soft' 
            ELSE 'Other' 
        END AS item_category_flag
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_product_name LIKE '%-01%'
      AND r.r_reason_desc LIKE '%damage%'
      AND regexp_like(i.i_item_desc, '(?i)soft')
)
SELECT 
    ib_lower_bound,
    ib_upper_bound,
    item_category_flag,
    COUNT(*) AS return_cnt,
    SUM(return_amt) AS total_return_amount,
    AVG(return_quantity) AS avg_quantity,
    COUNT(DISTINCT customer_name) AS unique_customers
FROM returns
GROUP BY ib_lower_bound, ib_upper_bound, item_category_flag
ORDER BY total_return_amount DESC
LIMIT 20
