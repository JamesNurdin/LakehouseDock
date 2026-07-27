WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        p.p_promo_id,
        p.p_channel_demo,
        p.p_response_target,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_wholesale_cost
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE cs.cs_wholesale_cost > 20
      AND cs.cs_list_price < 200
      AND p.p_channel_demo = 'N'
      AND p.p_response_target >= 1
      AND ss.ss_wholesale_cost BETWEEN 10 AND 60
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
)
SELECT
    fs.cs_sold_date_sk,
    fs.cs_item_sk,
    fs.cs_quantity,
    fs.cs_ext_sales_price,
    fs.ss_quantity,
    fs.ss_ext_sales_price,
    fs.p_promo_id,
    fs.p_channel_demo,
    fs.p_response_target,
    (
        SELECT max(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_sk = fs.cs_promo_sk
    ) AS max_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY fs.p_promo_id ORDER BY fs.cs_ext_sales_price DESC) AS rn_item_by_sales,
    RANK() OVER (ORDER BY (fs.cs_net_profit + fs.ss_net_profit) DESC) AS profit_rank
FROM filtered_sales fs
WHERE EXISTS (
    SELECT 1
    FROM promotion p3
    WHERE p3.p_promo_sk = fs.cs_promo_sk
      AND p3.p_promo_name LIKE '%Clearance%'
)
ORDER BY profit_rank
LIMIT 100
