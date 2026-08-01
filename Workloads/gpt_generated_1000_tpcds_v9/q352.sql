WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_class,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
        regexp_extract(i.i_product_name, '([0-9]{3})', 1) AS promo_code
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE
        regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{3}')
        AND i.i_product_name LIKE '%-%'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_class,
        regexp_extract(i.i_product_name, '([0-9]{3})', 1)
)
SELECT
    isales.i_item_id,
    isales.i_product_name,
    isales.i_class,
    isales.total_net_paid,
    isales.total_net_profit,
    isales.profit_category,
    isales.promo_code,
    CASE
        WHEN isales.total_net_paid > (
            SELECT AVG(sub.total_net_paid)
            FROM (
                SELECT SUM(cs2.cs_net_paid) AS total_net_paid
                FROM catalog_sales cs2
                JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
                WHERE i2.i_class = isales.i_class
                GROUP BY i2.i_item_id
            ) sub
        ) THEN 1 ELSE 0 END AS high_demand_flag,
    ROW_NUMBER() OVER (PARTITION BY isales.i_class ORDER BY isales.total_net_paid DESC) AS class_rank
FROM item_sales isales
ORDER BY isales.total_net_paid DESC
LIMIT 100
