WITH month_key AS (
    SELECT d_year, d_month_seq, MIN(d_date_sk) AS month_date_sk
    FROM date_dim
    GROUP BY d_year, d_month_seq
),
month_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS order_count,
        SUM(cs.cs_ext_tax) AS total_tax
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    ms.d_year,
    ms.d_month_seq,
    ms.total_profit,
    ms.total_quantity,
    ms.order_count,
    ms.total_tax,
    CASE
        WHEN ms.total_tax / NULLIF(ms.total_profit,0) > 0.2 THEN 'HIGH TAX'
        ELSE 'NORMAL TAX'
    END AS tax_category,
    DENSE_RANK() OVER (PARTITION BY ms.d_year ORDER BY ms.total_tax DESC) AS tax_rank,
    ws.web_name,
    ws.web_gmt_offset,
    wp.wp_url,
    wp.wp_type
FROM month_sales ms
JOIN month_key mk ON ms.d_year = mk.d_year AND ms.d_month_seq = mk.d_month_seq
LEFT JOIN web_site ws ON ws.web_open_date_sk = mk.month_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = mk.month_date_sk
ORDER BY ms.d_year, tax_rank
