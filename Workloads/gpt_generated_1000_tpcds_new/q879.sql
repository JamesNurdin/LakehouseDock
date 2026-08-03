WITH sales_agg AS (
    SELECT
        cs_catalog_page_sk,
        cs_promo_sk,
        cs_sold_time_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_qty,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows
    WHERE cs_ext_tax > 10
      AND cs_ext_sales_price > 100
      AND cs_quantity >= 1
      AND cs_ext_discount_amt IS NOT NULL
    GROUP BY cs_catalog_page_sk, cs_promo_sk, cs_sold_time_sk
)
SELECT *
FROM (
    SELECT
        cp.cp_department,
        cp.cp_catalog_number,
        p.p_promo_name,
        t.t_shift,
        sa.total_sales,
        sa.total_qty,
        sa.sales_cnt,
        CASE
            WHEN p.p_channel_radio = 'Y' THEN 'Radio'
            WHEN p.p_channel_tv = 'Y' THEN 'TV'
            ELSE 'Other'
        END AS promo_channel,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY sa.total_sales DESC) AS dept_sales_rank,
        LAG(sa.total_sales) OVER (PARTITION BY cp.cp_department ORDER BY sa.total_sales DESC) AS prior_dept_sales,
        (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = sa.cs_promo_sk) AS max_promo_cost
    FROM sales_agg sa
    JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON sa.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON sa.cs_sold_time_sk = t.t_time_sk
    WHERE cp.cp_department IN ('Books', 'Electronics')
      AND p.p_discount_active = 'Y'
      AND t.t_shift = 'first'
      AND EXISTS (
            SELECT 1 FROM promotion p3
            WHERE p3.p_promo_sk = p.p_promo_sk
              AND p3.p_channel_email = 'Y'
        )
) q1
UNION DISTINCT
SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    p.p_promo_name,
    t.t_shift,
    sa.total_sales,
    sa.total_qty,
    sa.sales_cnt,
    CASE
        WHEN p.p_channel_radio = 'Y' THEN 'Radio'
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        ELSE 'Other'
    END AS promo_channel,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY sa.total_sales DESC) AS dept_sales_rank,
    LAG(sa.total_sales) OVER (PARTITION BY cp.cp_department ORDER BY sa.total_sales DESC) AS prior_dept_sales,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = sa.cs_promo_sk) AS max_promo_cost
FROM sales_agg sa
JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON sa.cs_promo_sk = p.p_promo_sk
JOIN time_dim t ON sa.cs_sold_time_sk = t.t_time_sk
WHERE cp.cp_department IN ('Books', 'Electronics')
  AND p.p_discount_active = 'Y'
  AND t.t_shift = 'first'
  AND EXISTS (
        SELECT 1 FROM promotion p3
        WHERE p3.p_promo_sk = p.p_promo_sk
          AND p3.p_channel_email = 'Y'
    )
ORDER BY total_sales DESC
OFFSET 10 LIMIT 100
