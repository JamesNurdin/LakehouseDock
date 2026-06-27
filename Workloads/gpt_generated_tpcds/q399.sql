WITH sales AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_moy,
        p.p_promo_name,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
)
SELECT
    s_store_name,
    d_year,
    d_moy,
    COALESCE(p_promo_name, 'No Promotion') AS promotion_name,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_ext_discount_amt) AS total_discount
FROM sales
GROUP BY
    s_store_name,
    d_year,
    d_moy,
    COALESCE(p_promo_name, 'No Promotion')
ORDER BY total_net_profit DESC
LIMIT 100
