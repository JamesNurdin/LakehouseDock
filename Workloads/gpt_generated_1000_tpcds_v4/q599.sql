WITH item_return_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_count,
        CASE
            WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High'
            ELSE 'Low'
        END AS return_level
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 20 AND 100
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND cd.cd_education_status = 'College'
      AND hd.hd_buy_potential = '>10000'
    GROUP BY cr.cr_item_sk, d.d_year
)
SELECT
    ira.d_year,
    i.i_item_id,
    i.i_product_name,
    ira.total_return_amount,
    ira.total_return_qty,
    ira.return_level,
    (
        SELECT AVG(total_return_amount)
        FROM item_return_agg
        WHERE d_year = ira.d_year
    ) AS avg_return_amount_year
FROM item_return_agg ira
JOIN item i ON ira.item_sk = i.i_item_sk
WHERE ira.total_return_amount > (
    SELECT 0.5 * MAX(total_return_amount)
    FROM item_return_agg
)
ORDER BY ira.total_return_amount DESC
LIMIT 100
