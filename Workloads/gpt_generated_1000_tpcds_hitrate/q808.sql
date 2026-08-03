WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_product_name,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt,
        MAX(cs.cs_sold_date_sk) AS latest_sale_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_product_name, '^[A-Z]{2}[0-9]{3}')
      AND sm.sm_carrier LIKE 'U%'
    GROUP BY i.i_item_sk, i.i_category, i.i_product_name, d.d_year
)
SELECT
    isd.i_category,
    isd.i_product_name,
    regexp_extract(isd.i_product_name, '([A-Z]{2}[0-9]{3})', 1) AS product_code,
    substring(isd.i_product_name, 1, 5) AS prod_prefix,
    isd.total_net_paid,
    isd.total_net_profit,
    CASE
        WHEN isd.total_net_profit > (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = isd.i_item_sk
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg,
    pl.profit_bucket,
    concat(isd.i_category, '-', pl.profit_bucket) AS category_bucket
FROM item_sales isd
CROSS JOIN (VALUES ('Low'), ('Medium'), ('High')) AS pl(profit_bucket)
WHERE isd.total_net_profit > 0
ORDER BY isd.total_net_profit DESC
LIMIT 100
