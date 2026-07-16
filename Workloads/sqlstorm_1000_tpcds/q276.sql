SELECT
    t.year,
    t.state,
    t.category,
    SUM(t.net_profit) AS total_net_profit,
    SUM(t.ext_sales_price) AS total_sales,
    SUM(t.quantity) AS total_quantity
FROM (
    SELECT d.d_year AS year,
           s.s_state AS state,
           i.i_category AS category,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year AS year,
           cc.cc_state AS state,
           i.i_category AS category,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year AS year,
           ws_site.web_state AS state,
           i.i_category AS category,
           ws.ws_net_profit AS net_profit,
           ws.ws_ext_sales_price AS ext_sales_price,
           ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
) t
WHERE t.year BETWEEN 1999 AND 2001
  AND t.state IN ('CA', 'TX', 'NY')
GROUP BY t.year, t.state, t.category
ORDER BY total_net_profit DESC
LIMIT 100
