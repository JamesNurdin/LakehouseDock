SELECT
    d_year,
    d_month,
    metric,
    amount
FROM (
    SELECT
        d.d_year AS d_year,
        d.d_moy AS d_month,
        'sales' AS metric,
        SUM(cs.cs_ext_sales_price) AS amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, d.d_moy

    UNION ALL

    SELECT
        d.d_year AS d_year,
        d.d_moy AS d_month,
        'returns' AS metric,
        SUM(wr.wr_return_amt) AS amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wr.wr_return_amt > 0
    GROUP BY d.d_year, d.d_moy
) AS combined
ORDER BY d_year, d_month, metric
LIMIT 100
