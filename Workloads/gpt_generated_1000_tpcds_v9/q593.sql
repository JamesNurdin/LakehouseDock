WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_addr_sk,
        cs.cs_list_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_order_number,
        cs.cs_promo_sk
    FROM catalog_sales cs
    WHERE cs.cs_ship_addr_sk IN (4806430, 572777, 702119)
      AND cs.cs_list_price > 50.0
      AND cs.cs_quantity >= 2
      AND cs.cs_net_profit > 0
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    f.cs_ship_addr_sk,
    SUM(f.cs_ext_sales_price) AS total_sales,
    AVG(f.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT f.cs_order_number) AS order_cnt,
    MAX(f.cs_net_profit) AS max_profit,
    COALESCE(p.p_promo_name, 'No Promotion') AS promo_name_coalesce,
    (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_promo_sk = f.cs_promo_sk
    ) AS avg_sales_per_promo
FROM filtered_sales f
LEFT OUTER JOIN promotion p
    ON f.cs_promo_sk = p.p_promo_sk
WHERE p.p_channel_catalog = 'N'
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    f.cs_ship_addr_sk,
    f.cs_promo_sk
ORDER BY total_sales DESC
LIMIT 100
