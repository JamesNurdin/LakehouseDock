WITH sold_dates AS (
    SELECT DISTINCT
        cs.cs_sold_date_sk,
        cs.cs_net_paid_inc_ship_tax,
        d.d_year
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
),
store_sales AS (
    SELECT
        'store_closed' AS source_type,
        sd.d_year,
        SUM(sd.cs_net_paid_inc_ship_tax) AS total_net_paid
    FROM sold_dates sd
    JOIN store s
        ON s.s_closed_date_sk = sd.cs_sold_date_sk
    WHERE s.s_state = 'CA'
    GROUP BY sd.d_year
),
web_sales AS (
    SELECT
        'web_open' AS source_type,
        sd.d_year,
        SUM(sd.cs_net_paid_inc_ship_tax) AS total_net_paid
    FROM sold_dates sd
    JOIN web_site w
        ON w.web_open_date_sk = sd.cs_sold_date_sk
    WHERE w.web_mkt_class LIKE '%service%'
    GROUP BY sd.d_year
)
SELECT DISTINCT source_type,
                d_year,
                total_net_paid
FROM (
    SELECT * FROM store_sales
    UNION ALL
    SELECT * FROM web_sales
) combined
ORDER BY source_type, d_year
