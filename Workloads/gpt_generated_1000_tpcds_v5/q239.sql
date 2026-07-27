WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_time_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_sales_price) AS avg_sales_price
    FROM catalog_sales
    WHERE cs_ext_sales_price > 50.00
      AND cs_quantity >= 1
      AND cs_ship_addr_sk IN (2869440, 3187259)
    GROUP BY cs_item_sk, cs_sold_time_sk
),
reason_set AS (
    SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%Defect%'
    UNION
    SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%Customer%'
),
overall_avg_return AS (
    SELECT AVG(cr_return_amount) AS avg_ret_amount
    FROM catalog_returns
    WHERE cr_return_quantity > 0
)
SELECT
    r.r_reason_desc,
    t_ret.t_sub_shift,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    SUM(sa.total_sales) AS sum_sales_amount,
    AVG(sa.avg_sales_price) AS avg_item_price
FROM catalog_returns cr
JOIN sales_agg sa
    ON cr.cr_item_sk = sa.cs_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
WHERE cr.cr_return_quantity > 1
  AND cr.cr_return_amount > 20.00
  AND cr.cr_returning_addr_sk = 5901155
  AND t_ret.t_sub_shift = 'evening'
  AND cr.cr_reason_sk IN (SELECT r_reason_sk FROM reason_set)
  AND cr.cr_return_amount > (SELECT avg_ret_amount FROM overall_avg_return)
GROUP BY r.r_reason_desc, t_ret.t_sub_shift
ORDER BY sum_return_amount DESC
LIMIT 100
