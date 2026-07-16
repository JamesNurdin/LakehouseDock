SELECT d.d_year AS year,
       i.i_category,
       SUM(s.sales_net_profit) AS total_net_profit,
       SUM(s.sales_ext_sales_price) AS total_sales,
       AVG(s.sales_quantity) AS avg_quantity,
       COUNT(DISTINCT s.sales_order_number) AS distinct_orders
FROM (
    SELECT cs_sold_date_sk AS sales_date_sk,
           cs_item_sk AS sales_item_sk,
           cs_promo_sk AS sales_promo_sk,
           cs_quantity AS sales_quantity,
           cs_ext_sales_price AS sales_ext_sales_price,
           cs_net_profit AS sales_net_profit,
           cs_order_number AS sales_order_number
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_promo_sk,
           ss_quantity,
           ss_ext_sales_price,
           ss_net_profit,
           ss_ticket_number
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_promo_sk,
           ws_quantity,
           ws_ext_sales_price,
           ws_net_profit,
           ws_order_number
    FROM web_sales
) s
JOIN date_dim d ON s.sales_date_sk = d.d_date_sk
JOIN item i ON s.sales_item_sk = i.i_item_sk
JOIN promotion p ON s.sales_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
  AND d.d_year = 2001
GROUP BY d.d_year, i.i_category
ORDER BY total_net_profit DESC
LIMIT 100
