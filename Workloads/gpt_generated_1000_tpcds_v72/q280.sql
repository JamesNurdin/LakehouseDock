SELECT
    i.i_item_sk,
    i.i_product_name,
    CONCAT(i.i_brand, ' ', i.i_category) AS brand_category,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_flag
FROM
    catalog_sales cs
JOIN
    item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN
    promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN
    ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN
    time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
WHERE
    REGEXP_LIKE(i.i_item_desc, '(?i)br')
    AND i.i_product_name LIKE '%COOL%'
    AND REGEXP_LIKE(p.p_promo_name, '^Promo[0-9]{2}$')
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_channel_tv = 'Y'
    )
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_category
HAVING
    SUM(cs.cs_ext_sales_price) > (
        SELECT AVG(item_sales)
        FROM (
            SELECT cs2.cs_item_sk, SUM(cs2.cs_ext_sales_price) AS item_sales
            FROM catalog_sales cs2
            GROUP BY cs2.cs_item_sk
        ) sub
    )
ORDER BY
    total_sales DESC
LIMIT 100
