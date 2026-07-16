WITH all_sales AS (
    SELECT cs_item_sk AS item_sk,
           cs_net_profit AS net_profit,
           cs_quantity AS quantity,
           cs_sold_time_sk AS sold_time_sk,
           cs_bill_addr_sk AS bill_addr_sk,
           cs_promo_sk AS promo_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2450100
    UNION ALL
    SELECT ss_item_sk,
           ss_net_profit,
           ss_quantity,
           ss_sold_time_sk,
           ss_addr_sk,
           ss_promo_sk
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450100
    UNION ALL
    SELECT ws_item_sk,
           ws_net_profit,
           ws_quantity,
           ws_sold_time_sk,
           ws_bill_addr_sk,
           ws_promo_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450100
),
agg_sales AS (
    SELECT i.i_category AS category,
           ca.ca_state AS state,
           t.t_hour AS hour_of_day,
           SUM(s.net_profit) AS total_net_profit,
           SUM(s.quantity) AS total_quantity,
           COUNT(DISTINCT s.item_sk) AS distinct_items_sold
    FROM all_sales s
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN customer_address ca ON s.bill_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON s.sold_time_sk = t.t_time_sk
    WHERE i.i_category = 'Electronics'
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_category, ca.ca_state, t.t_hour
)
SELECT category,
       state,
       hour_of_day,
       total_net_profit,
       total_quantity,
       distinct_items_sold,
       RANK() OVER (PARTITION BY category ORDER BY total_net_profit DESC) AS profit_rank_by_state
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 10
