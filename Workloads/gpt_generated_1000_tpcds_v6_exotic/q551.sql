WITH catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        SUM(cs.cs_net_paid) AS total_amount,
        CASE WHEN p.p_promo_id IS NOT NULL THEN 'Promo' ELSE 'Regular' END AS sales_type
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        d.d_year,
        CASE WHEN p.p_promo_id IS NOT NULL THEN 'Promo' ELSE 'Regular' END
    HAVING SUM(cs.cs_net_paid) > 10000
),
store_returns_agg AS (
    SELECT
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS total_amount,
        'Return' AS sales_type
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
    HAVING SUM(sr.sr_return_amt) > 5000
)
SELECT year, total_amount, sales_type
FROM catalog_sales_agg
UNION ALL
SELECT year, total_amount, sales_type
FROM store_returns_agg
ORDER BY year DESC, total_amount DESC
LIMIT 100
