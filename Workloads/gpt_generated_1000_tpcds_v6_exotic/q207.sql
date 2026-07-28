WITH sales_agg AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(p.p_promo_name, 'a')
      AND cc.cc_city LIKE 'A%'
    GROUP BY d.d_year, p.p_promo_name
)
SELECT
    d_year,
    p_promo_name,
    total_net_paid,
    row_number() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rank_in_year,
    regexp_extract(p_promo_name, '(\\w{3})', 1) AS promo_prefix,
    concat(substr(p_promo_name, 1, 3), '-', cast(d_year as varchar)) AS promo_year_code
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
