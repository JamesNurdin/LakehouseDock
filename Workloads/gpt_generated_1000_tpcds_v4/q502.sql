WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        w.w_warehouse_name,
        w.w_city,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(p.p_promo_name, '[0-9]{2}')
      AND w.w_city LIKE '%York%'
    GROUP BY p.p_promo_sk, p.p_promo_name, w.w_warehouse_name, w.w_city
)
SELECT
    ps.p_promo_sk,
    ps.p_promo_name,
    ps.w_warehouse_name,
    ps.w_city,
    ps.total_profit,
    ps.total_sales,
    CASE
        WHEN ps.total_profit > 100000 THEN 'High'
        WHEN ps.total_profit > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    regexp_extract(ps.p_promo_name, '(\\d+)', 1) AS promo_number,
    substr(ps.p_promo_name, 1, 5) AS promo_prefix,
    concat(ps.w_warehouse_name, ' - ', ps.p_promo_name) AS warehouse_promo,
    ROW_NUMBER() OVER (PARTITION BY ps.w_warehouse_name ORDER BY ps.total_profit DESC) AS profit_rank
FROM promo_sales ps
ORDER BY ps.total_profit DESC
LIMIT 100
