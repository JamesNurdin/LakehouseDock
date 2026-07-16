WITH promo_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
        SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS discount_rate,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM
        catalog_sales cs
    JOIN
        promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        cs.cs_sold_date_sk BETWEEN 2450846 AND 2450904
        AND cs.cs_quantity > 0
        AND p.p_channel_email = 'Y'
        AND p.p_discount_active = 'Y'
        AND cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY
        p.p_promo_id,
        p.p_promo_name
    HAVING
        SUM(cs.cs_net_profit) > 0
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.total_profit,
    p.total_sales,
    p.avg_discount_amount,
    p.discount_rate,
    p.distinct_orders,
    RANK() OVER (ORDER BY p.total_profit DESC) AS profit_rank
FROM
    promo_agg p
ORDER BY
    p.total_profit DESC
LIMIT 10
