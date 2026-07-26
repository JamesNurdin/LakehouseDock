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
        AVG(cs.cs_net_profit) AS avg_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_net_profit > 0
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    ms.d_year,
    ms.d_month_seq,
    ms.total_profit,
    ms.avg_profit,
    ms.total_quantity,
    ms.distinct_orders,
    CASE
        WHEN ms.total_profit > 1500000 THEN 'VERY HIGH'
        WHEN ms.total_profit > 800000 THEN 'HIGH'
        WHEN ms.total_profit > 300000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY ms.d_year ORDER BY ms.total_quantity DESC) AS quantity_rank,
    ws.web_name,
    ws.web_gmt_offset,
    wp.wp_url,
    wp.wp_type
FROM month_sales ms
JOIN month_key mk ON ms.d_year = mk.d_year AND ms.d_month_seq = mk.d_month_seq
LEFT JOIN web_site ws ON ws.web_open_date_sk = mk.month_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = mk.month_date_sk
ORDER BY ms.d_year, quantity_rank
