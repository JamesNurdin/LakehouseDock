WITH catalog_ret AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        r.r_reason_desc,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY i.i_item_id, i.i_product_name, r.r_reason_desc
),
web_ret AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        r.r_reason_desc,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        'web' AS source
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY i.i_item_id, i.i_product_name, r.r_reason_desc
)
SELECT *
FROM (
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
) combined
ORDER BY total_return_amount DESC, i_item_id
LIMIT 100
