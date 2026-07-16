WITH promo_sales AS (
    SELECT
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders
    FROM
        catalog_sales cs
    JOIN
        promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        cs.cs_ship_mode_sk IN (3, 8, 2, 15, 18)
        AND cs.cs_ext_sales_price > 1000
        AND p.p_start_date_sk <= cs.cs_sold_date_sk
        AND p.p_end_date_sk >= cs.cs_sold_date_sk
    GROUP BY
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email
    HAVING
        SUM(cs.cs_net_profit) > 0
)
SELECT
    p_promo_name,
    p_channel_tv,
    p_channel_email,
    total_net_profit,
    total_sales,
    avg_discount,
    num_orders,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (ORDER BY total_net_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit
FROM
    promo_sales
ORDER BY
    profit_rank
LIMIT 10
