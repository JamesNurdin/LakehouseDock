WITH filtered AS (
    SELECT
        cr.cr_returning_hdemo_sk,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_return_amount,
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cs.cs_sales_price,
        cs.cs_ext_wholesale_cost,
        r.r_reason_desc,
        r.r_reason_id
    FROM catalog_returns AS cr
    JOIN catalog_sales AS cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason AS r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_fee > 20
      AND cr.cr_return_amount BETWEEN 10 AND 2000
      AND cr.cr_return_quantity <= 5
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
      AND cs.cs_sales_price > 5
      AND cs.cs_ext_wholesale_cost < 2000
      AND r.r_reason_id IN ('AAAAAAAAFAAAAAAA', 'AAAAAAAAADBAAAAAA')
), aggregated AS (
    SELECT
        r_reason_desc,
        cr_returning_hdemo_sk,
        COUNT(DISTINCT cr_order_number) AS orders_cnt,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cs_sales_price) AS avg_sales_price,
        MIN(cr_fee) AS min_fee,
        MAX(cr_fee) AS max_fee
    FROM filtered
    GROUP BY r_reason_desc, cr_returning_hdemo_sk
    HAVING SUM(cr_return_amount) > 1000
       AND COUNT(DISTINCT cr_order_number) >= 5
)
SELECT
    r_reason_desc,
    cr_returning_hdemo_sk,
    orders_cnt,
    total_return_amount,
    avg_sales_price,
    min_fee,
    max_fee
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
