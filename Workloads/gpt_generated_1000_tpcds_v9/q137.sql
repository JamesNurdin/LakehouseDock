WITH base_sales AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        d.d_current_quarter,
        p.p_channel_dmail,
        p.p_cost,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_sales_price,
        CASE WHEN p.p_channel_dmail = 'Y' THEN 'DirectMail' ELSE 'Other' END AS promo_channel_type
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT
            p1.p_promo_sk,
            p1.p_channel_dmail,
            p1.p_cost
        FROM promotion p1
        WHERE p1.p_start_date_sk = d.d_date_sk
          AND p1.p_promo_sk = ss.ss_promo_sk
    ) p
    WHERE d.d_year = 2001
      AND d.d_quarter_seq IN (10, 13)
      AND d.d_current_quarter = 'Y'
      AND p.p_channel_dmail = 'Y'
      AND ss.ss_quantity > 1
      AND ss.ss_net_paid_inc_tax > 1000
),
agg_sales AS (
    SELECT
        d_year,
        d_quarter_seq,
        promo_channel_type,
        COUNT(*) AS sales_count,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_paid_inc_tax) AS avg_net_paid,
        MIN(ss_net_paid_inc_tax) AS min_net_paid,
        MAX(ss_net_paid_inc_tax) AS max_net_paid,
        SUM(
            CASE WHEN p_cost > (SELECT AVG(p2.p_cost) FROM promotion p2)
                 THEN ss_ext_sales_price
                 ELSE 0
            END
        ) AS sales_with_high_promo_cost
    FROM base_sales
    GROUP BY ROLLUP (d_year, d_quarter_seq, promo_channel_type)
)
SELECT
    d_year,
    d_quarter_seq,
    promo_channel_type,
    sales_count,
    total_quantity,
    total_sales,
    avg_net_paid,
    min_net_paid,
    max_net_paid,
    sales_with_high_promo_cost,
    SUM(total_sales) OVER (PARTITION BY d_year) AS yearly_sales_total,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg_sales
ORDER BY d_year, d_quarter_seq, promo_channel_type
LIMIT 100
