SELECT t.d_year,
       t.state,
       t.i_brand,
       t.i_class,
       t.i_category,
       SUM(t.profit) AS total_profit,
       COUNT(*) AS total_transactions
FROM (
    SELECT d.d_year,
           s.s_state AS state,
           i.i_brand,
           i.i_class,
           i.i_category,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           w.w_state AS state,
           i.i_brand,
           i.i_class,
           i.i_category,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           w.w_state AS state,
           i.i_brand,
           i.i_class,
           i.i_category,
           ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
) t
WHERE t.d_year = 2002
GROUP BY t.d_year, t.state, t.i_brand, t.i_class, t.i_category
ORDER BY total_profit DESC
LIMIT 100
