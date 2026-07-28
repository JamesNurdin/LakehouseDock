WITH filtered_items AS (
    SELECT i_item_sk
    FROM tpcds.item
    WHERE i_current_price > 50
      AND i_product_name LIKE '%COFFEE%'
),
sales_agg AS (
    SELECT
        d.d_year,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d{3})') AS promo_code,
        CONCAT(p.p_promo_name, '_', p.p_channel_details) AS promo_full,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN filtered_items fi
      ON cs.cs_item_sk = fi.i_item_sk
    WHERE REGEXP_LIKE(p.p_promo_name, 'PROMO[0-9]{3}')
      AND SUBSTRING(p.p_channel_details, 1, 5) = 'Online'
    GROUP BY d.d_year,
             REGEXP_EXTRACT(p.p_promo_name, '(\\d{3})'),
             CONCAT(p.p_promo_name, '_', p.p_channel_details)
)
SELECT
    s.d_year,
    s.promo_code,
    s.promo_full,
    s.total_net_paid,
    s.orders_count,
    SUM(s.total_net_paid) OVER (
        PARTITION BY s.d_year
        ORDER BY s.promo_code
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM sales_agg s
WHERE s.total_net_paid > (
    SELECT AVG(cs2.cs_net_paid)
    FROM tpcds.catalog_sales cs2
    JOIN tpcds.date_dim d2
      ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = s.d_year
)
ORDER BY s.d_year, s.promo_code
