WITH unified AS (
    -- First sub‑select: promotion start date matches customer's first sales date
    SELECT
        c.c_customer_id,
        d.d_year,
        p.p_promo_id,
        p.p_cost,
        CASE
            WHEN p.p_discount_active = 'N' AND p.p_channel_email = 'N' THEN 'Passive'
            ELSE 'Active'
        END AS promo_category
    FROM customer c
    JOIN date_dim d
        ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
        AND d.d_weekend = 'N'
        AND p.p_discount_active = 'N'
        AND p.p_channel_email = 'N'
        AND c.c_preferred_cust_flag = 'Y'

    UNION ALL

    -- Second sub‑select: promotion end date matches customer's first ship‑to date
    SELECT
        c.c_customer_id,
        d.d_year,
        p.p_promo_id,
        p.p_cost,
        CASE
            WHEN p.p_discount_active = 'N' AND p.p_channel_email = 'N' THEN 'Passive'
            ELSE 'Active'
        END AS promo_category
    FROM customer c
    JOIN date_dim d
        ON c.c_first_shipto_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_end_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
        AND d.d_weekend = 'N'
        AND p.p_discount_active = 'N'
        AND p.p_channel_email = 'N'
        AND c.c_preferred_cust_flag = 'Y'
),

agg AS (
    SELECT
        d_year,
        p_promo_id,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        SUM(p_cost) AS total_cost,
        SUM(CASE WHEN promo_category = 'Passive' THEN p_cost ELSE 0 END) AS passive_cost
    FROM unified
    GROUP BY CUBE (d_year, p_promo_id)
),

ranked AS (
    SELECT
        d_year,
        p_promo_id,
        distinct_customers,
        total_cost,
        passive_cost,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_cost DESC) AS cost_rank
    FROM agg
)
SELECT
    d_year,
    p_promo_id,
    distinct_customers,
    total_cost,
    passive_cost,
    cost_rank
FROM ranked
WHERE cost_rank <= 10
ORDER BY d_year DESC NULLS LAST, cost_rank
LIMIT 100
