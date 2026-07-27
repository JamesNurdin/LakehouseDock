WITH sales_promo AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_tax,
        cs.cs_list_price,
        cs.cs_promo_sk,
        p.p_promo_id,
        p.p_channel_tv,
        p.p_channel_dmail,
        CASE WHEN cs.cs_quantity >= 10 THEN 'Bulk' ELSE 'Regular' END AS order_type
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_tax > 20
        AND cs.cs_list_price BETWEEN 80 AND 200
        AND cs.cs_quantity > 1
        AND p.p_channel_tv = 'Y'
)
SELECT
    sp.cs_order_number,
    sp.cs_sold_date_sk,
    sp.p_promo_id,
    sp.order_type,
    sp.cs_net_paid,
    sp.cs_net_profit,
    AVG(sp.cs_net_profit) OVER (PARTITION BY sp.p_promo_id) AS avg_profit_per_promo,
    RANK() OVER (ORDER BY sp.cs_net_profit DESC) AS profit_rank,
    CASE
        WHEN sp.cs_net_profit > (
            SELECT AVG(cs_net_profit)
            FROM catalog_sales
            WHERE cs_promo_sk = sp.cs_promo_sk
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM sales_promo sp
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = sp.cs_promo_sk
      AND p2.p_channel_dmail = 'Y'
)
ORDER BY profit_rank
LIMIT 100
