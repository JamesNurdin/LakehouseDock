WITH base AS (
    SELECT
        cp.cp_department AS department,
        t.t_shift AS shift,
        cs.cs_net_paid_inc_ship_tax AS sales_amount
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cp.cp_end_date_sk > 2451000
      AND cp.cp_description LIKE '%store%'
      AND cs.cs_wholesale_cost < 80
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND cs.cs_net_paid_inc_ship_tax > 500
      AND p.p_channel_radio = 'N'
      AND p.p_channel_press = 'N'
      AND t.t_shift = 'Evening'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_discount_active = 'Y'
      )
),
agg AS (
    SELECT
        department,
        shift,
        SUM(sales_amount) AS sum_sales,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY department, shift
)
SELECT
    department,
    shift,
    sum_sales,
    txn_count,
    RANK() OVER (PARTITION BY department ORDER BY sum_sales DESC) AS dept_sales_rank,
    SUM(sum_sales) OVER (
        PARTITION BY department
        ORDER BY sum_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales
FROM agg
ORDER BY sum_sales DESC
LIMIT 20
