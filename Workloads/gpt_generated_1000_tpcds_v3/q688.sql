WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
cs_agg AS (
    SELECT cs_item_sk,
           cs_call_center_sk,
           SUM(cs_net_paid) AS total_net_paid,
           SUM(cs_net_profit) AS total_net_profit,
           COUNT(*) AS cs_order_count
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_call_center_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    inv.total_quantity_on_hand,
    cs.total_net_paid,
    cs.total_net_profit,
    CASE
        WHEN cs.total_net_profit > 10000 THEN 'Very High'
        WHEN cs.total_net_profit > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS profit_category,
    ss.ss_quantity,
    ss.ss_net_paid,
    td_sold.t_hour,
    RANK() OVER (PARTITION BY cc.cc_market_manager ORDER BY cs.total_net_profit DESC) AS profit_rank_by_market_manager
FROM cs_agg cs
INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
INNER JOIN inv_agg inv ON i.i_item_sk = inv.inv_item_sk
INNER JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
INNER JOIN time_dim td_sold ON ss.ss_sold_time_sk = td_sold.t_time_sk
INNER JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
INNER JOIN time_dim td_return ON sr.sr_return_time_sk = td_return.t_time_sk
WHERE
    cc.cc_country = 'USA'
    AND cc.cc_gmt_offset >= -5
    AND i.i_current_price >= 50
    AND i.i_brand = 'Brand#23'
    AND inv.total_quantity_on_hand > 0
    AND td_sold.t_hour BETWEEN 9 AND 17
ORDER BY cs.total_net_profit DESC, profit_rank_by_market_manager
LIMIT 100
