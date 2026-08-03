WITH item_extracted AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '(\\d{4})') AS four_digit_code,
        CASE
            WHEN regexp_like(i.i_product_name, 'Premium') THEN 'Premium'
            ELSE 'Standard'
        END AS product_category
    FROM item i
    WHERE regexp_like(i.i_item_desc, '\\d{4}')
      AND i.i_product_name LIKE '%Premium%'
)
SELECT
    d.d_year,
    d.d_month_seq,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    COUNT(cr.cr_return_quantity) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    CASE
        WHEN SUM(cr.cr_return_amount) > 10000 THEN 'High'
        ELSE 'Low'
    END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS rn,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    li.four_digit_code,
    pn.product_name_len
FROM catalog_returns cr
RIGHT OUTER JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN item_extracted ie
    ON cr.cr_item_sk = ie.i_item_sk
LEFT JOIN LATERAL (
    SELECT ie.four_digit_code
) AS li ON TRUE
LEFT JOIN LATERAL (
    SELECT length(ie.i_product_name) AS product_name_len
) AS pn ON TRUE
GROUP BY
    d.d_year,
    d.d_month_seq,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    c.c_first_name,
    c.c_last_name,
    li.four_digit_code,
    pn.product_name_len
ORDER BY
    d.d_year DESC,
    total_return_amount DESC
LIMIT 100
