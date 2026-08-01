WITH joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_ext_wholesale_cost,
        cs.cs_ext_tax,
        p.p_promo_id,
        p.p_promo_name
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        p.p_channel_demo = 'N'
        AND p.p_channel_event = 'N'
        AND p.p_response_target >= 1
        AND cs.cs_net_paid_inc_tax > 500.00
        AND cs.cs_quantity >= 2
        AND cs.cs_ext_wholesale_cost BETWEEN 1000 AND 5000
),
aggregated AS (
    SELECT
        p_promo_id,
        p_promo_name,
        cs_sold_date_sk,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_tax) AS avg_tax
    FROM joined cs
    GROUP BY
        p_promo_id,
        p_promo_name,
        cs_sold_date_sk
)
SELECT
    p_promo_id,
    p_promo_name,
    cs_sold_date_sk,
    total_sales,
    total_quantity,
    avg_tax,
    RANK() OVER (PARTITION BY cs_sold_date_sk ORDER BY total_sales DESC) AS rank_sales_by_date,
    SUM(total_sales) OVER (PARTITION BY p_promo_id ORDER BY cs_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_total_3days
FROM aggregated
ORDER BY
    total_sales DESC,
    p_promo_id
LIMIT 100
