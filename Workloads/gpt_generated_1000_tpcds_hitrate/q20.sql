WITH catalog_agg AS (
    SELECT
        td.t_hour AS sale_hour,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE p.p_discount_active = 'N'
      AND td.t_hour BETWEEN 8 AND 20
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY td.t_hour
),
web_agg AS (
    SELECT
        td.t_hour AS sale_hour,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE p.p_discount_active = 'N'
      AND td.t_hour BETWEEN 8 AND 20
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY td.t_hour
),
combined_sales AS (
    SELECT sale_hour, channel, total_net_paid FROM catalog_agg
    UNION ALL
    SELECT sale_hour, channel, total_net_paid FROM web_agg
)
SELECT sale_hour, channel, total_net_paid
FROM combined_sales
ORDER BY sale_hour DESC, total_net_paid DESC
LIMIT 100
