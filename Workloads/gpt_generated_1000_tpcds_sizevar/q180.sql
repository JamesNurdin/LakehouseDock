WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_product_name,
        i_color
    FROM
        item
    WHERE
        i_color LIKE 'R%'
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    cd.cd_gender,
    COUNT(cr.cr_order_number) AS return_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    regexp_extract(fi.i_item_desc, '(\\d+)', 1) AS extracted_code,
    CASE WHEN regexp_like(fi.i_product_name, '(?i)premium') THEN 1 ELSE 0 END AS is_premium
FROM
    catalog_returns cr
    JOIN filtered_items fi ON cr.cr_item_sk = fi.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE
    LOWER(r.r_reason_desc) LIKE '%damage%'
    AND cr.cr_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_desc LIKE '%size%')
GROUP BY
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name),
    cd.cd_gender,
    fi.i_item_desc,
    fi.i_product_name
ORDER BY
    total_return_amount DESC
LIMIT 100
