SELECT d.d_year,
       t.state,
       t.i_category,
       SUM(t.sales) AS total_sales,
       SUM(t.profit) AS total_profit
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           w.w_state AS state,
           i.i_category AS i_category,
           cs.cs_net_paid AS sales,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           s.s_state,
           i.i_category,
           ss.ss_net_paid,
           ss.ss_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           web.web_state,
           i.i_category,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
) t
JOIN date_dim d ON t.date_sk = d.d_date_sk
GROUP BY d.d_year, t.state, t.i_category
ORDER BY d.d_year, t.state, t.i_category
