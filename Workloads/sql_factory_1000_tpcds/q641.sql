WITH month_key AS (
    SELECT d_year, d_month_seq, MAX(d_date_sk) AS month_date_sk
    FROM date_dim
    GROUP BY d_year, d_month_seq
),
month_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid_inc_tax) AS total_paid_inc_tax,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        COUNT(*) FILTER (WHERE cs.cs_coupon_amt > 0) AS coupon_orders,
        SUM(cs.cs_ext_tax) AS total_tax
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    ms.d_year,
    ms.d_month_seq,
    ms.total_paid_inc_tax,
    ms.total_ship_cost,
    ms.coupon_orders,
    ms.total_tax,
    CASE WHEN ms.total_ship_cost / NULLIF(ms.total_paid_inc_tax,0) > 0.15 THEN 'EXPENSIVE SHIP' ELSE 'NORMAL SHIP' END AS ship_category,
    RANK() OVER (PARTITION BY ms.d_year ORDER BY ms.total_tax ASC) AS tax_rank_asc,
    ws.web_name,
    ws.web_gmt_offset,
    wp.wp_url,
    wp.wp_type
FROM month_sales ms
JOIN month_key mk ON ms.d_year = mk.d_year AND ms.d_month_seq = mk.d_month_seq
LEFT JOIN web_site ws ON ws.web_open_date_sk = mk.month_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = mk.month_date_sk
ORDER BY ms.d_year, tax_rank_asc
