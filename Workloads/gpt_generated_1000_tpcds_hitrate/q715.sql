/* goal: Identify the top‑3 ship modes by total profit for each promotion, including subtotals and a grand total, for promotions that started in 2001 (carrier GREAT EASTERN) or 2002 (carrier ORIENTAL). */
WITH sales_union AS (
    /* 2001 promotions shipped by GREAT EASTERN */
    SELECT
        p.p_promo_id,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        cs.cs_ext_sales_price      AS sales_amount,
        cs.cs_net_profit           AS profit,
        d.d_year
    FROM catalog_sales cs
    JOIN promotion p      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d       ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE p.p_start_date_sk BETWEEN (
            SELECT d1.d_date_sk FROM date_dim d1 WHERE d1.d_date = DATE '2001-01-01')
          AND (
            SELECT d1.d_date_sk FROM date_dim d1 WHERE d1.d_date = DATE '2001-12-31')
      AND sm.sm_carrier = 'GREAT EASTERN'

    UNION

    /* 2002 promotions shipped by ORIENTAL */
    SELECT
        p.p_promo_id,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        cs.cs_ext_sales_price      AS sales_amount,
        cs.cs_net_profit           AS profit,
        d.d_year
    FROM catalog_sales cs
    JOIN promotion p      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d       ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE p.p_start_date_sk BETWEEN (
            SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_date = DATE '2002-01-01')
          AND (
            SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_date = DATE '2002-12-31')
      AND sm.sm_carrier = 'ORIENTAL'
),
agg AS (
    SELECT
        p_promo_id,
        sm_ship_mode_id,
        sm_carrier,
        d_year,
        SUM(sales_amount) AS total_sales,
        SUM(profit)       AS total_profit
    FROM sales_union
    GROUP BY ROLLUP (p_promo_id, sm_ship_mode_id, sm_carrier, d_year)
),
ranked AS (
    SELECT
        p_promo_id,
        sm_ship_mode_id,
        sm_carrier,
        d_year,
        total_sales,
        total_profit,
        CASE
            WHEN sm_ship_mode_id IS NOT NULL THEN
                RANK() OVER (PARTITION BY p_promo_id ORDER BY total_profit DESC)
        END AS profit_rank
    FROM agg
)
SELECT
    p_promo_id,
    sm_ship_mode_id,
    sm_carrier,
    d_year,
    total_sales,
    total_profit,
    profit_rank
FROM ranked
WHERE profit_rank IS NULL OR profit_rank <= 3
ORDER BY p_promo_id, profit_rank
LIMIT 100
