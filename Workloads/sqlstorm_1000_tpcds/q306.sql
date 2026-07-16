WITH sales_union AS (
    SELECT cs.cs_item_sk AS item_sk,
           cc.cc_state AS state,
           d.d_year AS year,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           1 AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT ss.ss_item_sk,
           s.s_state,
           d.d_year,
           ss.ss_net_paid,
           ss.ss_net_profit,
           1
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT ws.ws_item_sk,
           w.w_state,
           d.d_year,
           ws.ws_net_paid,
           ws.ws_net_profit,
           1
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
agg_sales AS (
    SELECT item_sk,
           state,
           year,
           SUM(net_paid) AS total_net_paid,
           SUM(net_profit) AS total_net_profit,
           SUM(sales_cnt) AS total_sales_cnt
    FROM sales_union
    GROUP BY item_sk, state, year
),
item_detail AS (
    SELECT i.i_item_sk,
           i.i_item_desc,
           i.i_category,
           i.i_brand
    FROM item i
),
ranked_sales AS (
    SELECT a.year,
           a.state,
           d.i_item_desc,
           d.i_category,
           d.i_brand,
           a.total_net_paid,
           a.total_net_profit,
           a.total_sales_cnt,
           ROW_NUMBER() OVER (PARTITION BY a.year ORDER BY a.total_net_profit DESC) AS profit_rank
    FROM agg_sales a
    JOIN item_detail d ON a.item_sk = d.i_item_sk
    WHERE a.total_sales_cnt > 0
)
SELECT year,
       state,
       i_item_desc,
       i_category,
       i_brand,
       total_net_paid,
       total_net_profit,
       total_sales_cnt,
       profit_rank
FROM ranked_sales
WHERE profit_rank <= 10
ORDER BY year, profit_rank
