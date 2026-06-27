WITH store_agg AS (
    SELECT
        'store' AS channel,
        promotion.p_promo_id,
        sum(store_sales.ss_net_profit) AS net_profit
    FROM store_sales
    JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
    JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
    JOIN customer_demographics ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE time_dim.t_hour >= 6
      AND time_dim.t_hour < 12
      AND customer_demographics.cd_gender = 'M'
    GROUP BY promotion.p_promo_id
),
catalog_agg AS (
    SELECT
        'catalog' AS channel,
        promotion.p_promo_id,
        sum(catalog_sales.cs_net_profit) AS net_profit
    FROM catalog_sales
    JOIN promotion ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    JOIN time_dim ON catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
    JOIN customer ON catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
    JOIN customer_demographics ON catalog_sales.cs_bill_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE time_dim.t_hour >= 6
      AND time_dim.t_hour < 12
      AND customer_demographics.cd_gender = 'M'
    GROUP BY promotion.p_promo_id
),
web_agg AS (
    SELECT
        'web' AS channel,
        promotion.p_promo_id,
        sum(web_sales.ws_net_profit) AS net_profit
    FROM web_sales
    JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
    JOIN time_dim ON web_sales.ws_sold_time_sk = time_dim.t_time_sk
    JOIN customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    JOIN customer_demographics ON web_sales.ws_bill_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE time_dim.t_hour >= 6
      AND time_dim.t_hour < 12
      AND customer_demographics.cd_gender = 'M'
    GROUP BY promotion.p_promo_id
)
SELECT
    channel,
    p_promo_id,
    sum(net_profit) AS total_net_profit
FROM (
    SELECT channel, p_promo_id, net_profit FROM store_agg
    UNION ALL
    SELECT channel, p_promo_id, net_profit FROM catalog_agg
    UNION ALL
    SELECT channel, p_promo_id, net_profit FROM web_agg
) AS combined
GROUP BY channel, p_promo_id
ORDER BY total_net_profit DESC
LIMIT 20
