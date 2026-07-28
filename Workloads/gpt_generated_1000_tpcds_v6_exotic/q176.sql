WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d_start.d_year AS start_year,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        MAX(cs.cs_net_paid) AS max_net_paid,
        CASE
            WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High'
            ELSE 'Low'
        END AS profit_category,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_code_extracted,
        substring(p.p_promo_name FROM 1 FOR 5) AS promo_name_prefix,
        concat(p.p_promo_name, '_', d_start.d_day_name) AS promo_day_label
    FROM
        promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    WHERE
        regexp_like(p.p_promo_name, '[A-Za-z]+\\d+')
        AND p.p_promo_name LIKE '%Sale%'
        AND d_sold.d_year = d_start.d_year
        AND NOT EXISTS (
            SELECT 1
            FROM catalog_sales cs2
            WHERE cs2.cs_promo_sk = p.p_promo_sk
              AND cs2.cs_quantity > 1000
        )
    GROUP BY
        p.p_promo_sk,
        p.p_promo_name,
        d_start.d_year,
        d_start.d_day_name
)
SELECT
    ps.p_promo_sk,
    ps.p_promo_name,
    ps.start_year,
    ps.total_net_profit,
    ps.profit_category,
    ps.promo_code_extracted,
    ps.promo_name_prefix,
    ps.promo_day_label,
    ps.distinct_orders,
    ps.max_net_paid,
    RANK() OVER (PARTITION BY ps.start_year ORDER BY ps.total_net_profit DESC) AS profit_rank_year
FROM
    promo_sales ps
WHERE
    ps.total_net_profit IS NOT NULL
ORDER BY
    ps.start_year DESC,
    ps.total_net_profit DESC
LIMIT 100
