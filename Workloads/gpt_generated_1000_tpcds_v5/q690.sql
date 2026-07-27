WITH sales_returns AS (
    SELECT
        cs.cs_order_number AS cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_addr_sk,
        cs.cs_quantity,
        cs.cs_wholesale_cost,
        cs.cs_net_profit,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ca.ca_state,
        p.p_promo_id,
        p.p_channel_tv,
        p.p_channel_radio,
        t.t_second,
        t.t_minute,
        t.t_sub_shift
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE
        cs.cs_wholesale_cost > 20.00
        AND cs.cs_quantity >= 2
        AND p.p_channel_tv = 'N'
        AND p.p_channel_radio = 'N'
        AND t.t_second IN (16, 19)
        AND t.t_sub_shift = 'morning'
)
SELECT
    ca_state,
    p_channel_tv,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_net_profit) AS total_net_profit,
    AVG(cs_net_profit) AS avg_net_profit,
    SUM(cr_return_amount) AS total_return_amount,
    CASE
        WHEN SUM(cs_net_profit) > 10000 THEN 'High'
        WHEN SUM(cs_net_profit) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    MIN(cs_wholesale_cost) AS min_wholesale_cost,
    MAX(cs_wholesale_cost) AS max_wholesale_cost
FROM sales_returns
GROUP BY ca_state, p_channel_tv
ORDER BY total_net_profit DESC
LIMIT 100
