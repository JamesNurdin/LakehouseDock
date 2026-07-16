WITH sales AS (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_addr_sk AS addr_sk,
           ss_item_sk AS item_sk,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_ship_addr_sk,
           ws_item_sk,
           ws_net_paid,
           ws_net_profit,
           'web'
    FROM web_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_ship_addr_sk,
           cs_item_sk,
           cs_net_paid,
           cs_net_profit,
           'catalog'
    FROM catalog_sales
)
SELECT ca.ca_state,
       i.i_category,
       d.d_year,
       channel,
       SUM(net_paid) AS total_sales,
       SUM(net_profit) AS total_profit,
       COUNT(*) AS num_transactions
FROM sales
JOIN date_dim d ON sales.sold_date_sk = d.d_date_sk
JOIN customer_address ca ON sales.addr_sk = ca.ca_address_sk
JOIN item i ON sales.item_sk = i.i_item_sk
GROUP BY ca.ca_state, i.i_category, d.d_year, channel
ORDER BY total_sales DESC
LIMIT 100
