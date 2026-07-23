SELECT
    td.t_hour,
    td.t_sub_shift,
    td.t_meal_time,
    COUNT(*) AS sales_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_sales_price) AS avg_ext_sales_price,
    MIN(cs.cs_list_price) AS min_list_price,
    MAX(cs.cs_coupon_amt) AS max_coupon_amt
FROM
    catalog_sales cs
JOIN
    time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
WHERE
    cs.cs_list_price > 100.00
    AND cs.cs_coupon_amt BETWEEN 500.00 AND 1500.00
    AND cs.cs_quantity >= 2
    AND td.t_hour IN (9, 10, 11)
    AND td.t_sub_shift = 'morning'
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = cs.cs_item_sk
          AND cs2.cs_coupon_amt > 1000.00
    )
GROUP BY
    td.t_hour,
    td.t_sub_shift,
    td.t_meal_time
ORDER BY
    total_net_paid DESC
LIMIT 100
