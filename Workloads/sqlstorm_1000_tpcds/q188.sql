WITH returns_agg AS (
    SELECT cr_order_number, SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_order_number
)
SELECT d.d_year,
       SUM(cs.cs_net_paid) - COALESCE(SUM(r.total_return_amount), 0) AS net_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN returns_agg r ON cs.cs_order_number = r.cr_order_number
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year
ORDER BY d.d_year
