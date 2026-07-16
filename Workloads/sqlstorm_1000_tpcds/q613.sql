WITH unified_sales AS (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_store_sk AS channel_id,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           ss_quantity AS quantity,
           'store' AS channel,
           ss_item_sk AS item_sk,
           ss_promo_sk AS promo_sk,
           ss_customer_sk AS customer_sk
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_call_center_sk AS channel_id,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           cs_quantity AS quantity,
           'catalog' AS channel,
           cs_item_sk AS item_sk,
           cs_promo_sk AS promo_sk,
           cs_bill_customer_sk AS customer_sk
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk AS sold_date_sk,
           ws_web_site_sk AS channel_id,
           ws_net_paid AS net_paid,
           ws_net_profit AS net_profit,
           ws_quantity AS quantity,
           'web' AS channel,
           ws_item_sk AS item_sk,
           ws_promo_sk AS promo_sk,
           ws_bill_customer_sk AS customer_sk
    FROM web_sales
)
SELECT d.d_year,
       s.channel,
       SUM(s.net_paid) AS total_net_paid,
       SUM(s.net_profit) AS total_net_profit,
       COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
       COUNT(DISTINCT s.customer_sk) AS distinct_customers
FROM unified_sales s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, s.channel
ORDER BY d.d_year, s.channel
