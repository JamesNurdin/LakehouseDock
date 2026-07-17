WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        i.i_item_id,
        i.i_product_name,
        p.p_promo_id,
        p.p_start_date_sk,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    WHERE p.p_item_sk IN (287899, 268843)
    GROUP BY
        cs.cs_item_sk,
        cs.cs_promo_sk,
        i.i_item_id,
        i.i_product_name,
        p.p_promo_id,
        p.p_start_date_sk
)
SELECT
    i_item_id,
    i_product_name,
    p_promo_id,
    total_net_profit,
    CASE
        WHEN total_net_profit > 10000 THEN 'High'
        WHEN total_net_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY i_item_id ORDER BY total_net_profit DESC) AS promo_rank,
    DENSE_RANK() OVER (PARTITION BY i_item_id ORDER BY total_net_profit DESC) AS promo_dense_rank,
    ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY p_start_date_sk) AS promo_seq,
    SUM(total_net_profit) OVER (
        PARTITION BY i_item_id
        ORDER BY p_start_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_sum_last_3_promos
FROM sales_agg
ORDER BY i_item_id, promo_rank
