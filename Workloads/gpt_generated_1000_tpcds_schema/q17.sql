WITH sales_promo_warehouse AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_net_profit,
        cs.cs_sales_price,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '([0-9]{2})', 1) AS promo_code,
        w.w_warehouse_name,
        w.w_city,
        w.w_street_name,
        hd.hd_vehicle_count,
        concat(w.w_city, '-', regexp_extract(p.p_promo_name, '([0-9]{2})', 1)) AS city_promo_key
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(p.p_promo_name, '[A-Z]{3}[0-9]{2}')
      AND w.w_street_name LIKE 'A%'
      AND hd.hd_vehicle_count >= 2
)
SELECT
    spw.w_warehouse_name,
    spw.w_city,
    spw.p_promo_name,
    spw.promo_code,
    spw.city_promo_key,
    SUM(spw.cs_net_profit) AS total_net_profit,
    AVG(spw.cs_sales_price) AS avg_sales_price,
    COUNT(*) AS sales_count,
    RANK() OVER (PARTITION BY spw.w_city ORDER BY SUM(spw.cs_net_profit) DESC) AS profit_rank_in_city
FROM sales_promo_warehouse spw
GROUP BY
    spw.w_warehouse_name,
    spw.w_city,
    spw.p_promo_name,
    spw.promo_code,
    spw.city_promo_key
HAVING SUM(spw.cs_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
