WITH sales_union AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_sold_time_sk AS sold_time_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity,
           cs.cs_promo_sk AS promo_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_sold_time_sk,
           ws.ws_net_profit,
           ws.ws_quantity,
           ws.ws_promo_sk,
           'web' AS channel
    FROM web_sales ws
),
sales_enriched AS (
    SELECT su.sold_date_sk,
           t.t_hour,
           su.channel,
           su.net_profit,
           su.quantity,
           p.p_promo_name,
           p.p_discount_active
    FROM sales_union su
    JOIN time_dim t ON su.sold_time_sk = t.t_time_sk
    JOIN promotion p ON su.promo_sk = p.p_promo_sk
)
SELECT sold_date_sk,
       channel,
       SUM(net_profit) AS daily_profit,
       SUM(quantity) AS daily_quantity,
       PERCENT_RANK() OVER (PARTITION BY channel ORDER BY SUM(net_profit)) AS profit_percentile,
       MAX(SUM(net_profit)) OVER (PARTITION BY channel) AS max_daily_profit,
       CASE WHEN SUM(net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator
FROM sales_enriched
GROUP BY sold_date_sk, channel
ORDER BY profit_percentile ASC
