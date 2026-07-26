WITH month_key AS (
    SELECT d_year, d_month_seq, MIN(d_date_sk) AS month_date_sk
    FROM date_dim
    WHERE d_year >= 2016 AND d_year <= 2021
    GROUP BY d_year, d_month_seq
),
month_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        AVG(cs.cs_ext_tax) AS avg_tax
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2016 AND 2021
      AND cs.cs_quantity > 0
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    ms.d_year,
    ms.d_month_seq,
    ms.total_profit,
    ms.total_quantity,
    ms.distinct_orders,
    ms.avg_tax,
    CASE WHEN ms.avg_tax > 5 THEN 'HIGH AVG TAX' ELSE 'LOW AVG TAX' END AS tax_category,
    ROW_NUMBER() OVER (PARTITION BY ms.d_year ORDER BY ms.total_profit DESC) AS profit_rank,
    ws.web_name,
    ws.web_gmt_offset,
    wp.wp_url,
    wp.wp_type
FROM month_sales ms
JOIN month_key mk ON ms.d_year = mk.d_year AND ms.d_month_seq = mk.d_month_seq
LEFT JOIN web_site ws ON ws.web_open_date_sk = mk.month_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = mk.month_date_sk
ORDER BY ms.d_year, profit_rank DESC
