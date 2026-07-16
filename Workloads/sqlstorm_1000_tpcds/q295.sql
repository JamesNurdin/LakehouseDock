WITH cat_sales AS (
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        cc.cc_state AS state,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
),
store_sales_agg AS (
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        s.s_state AS state,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
),
web_sales_agg AS (
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        w.w_state AS state,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
),
union_sales AS (
 SELECT * FROM cat_sales
 UNION ALL
 SELECT * FROM store_sales_agg
 UNION ALL
 SELECT * FROM web_sales_agg
),
agg_sales AS (
 SELECT d_year,
        month_seq,
        i_category,
        state,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit
 FROM union_sales
 GROUP BY d_year, month_seq, i_category, state
)
SELECT d_year,
       month_seq,
       i_category,
       state,
       total_net_paid,
       total_net_profit,
       total_net_profit - LAG(total_net_profit) OVER (PARTITION BY i_category, state ORDER BY d_year, month_seq) AS profit_change,
       total_net_profit / NULLIF(LAG(total_net_profit) OVER (PARTITION BY i_category, state ORDER BY d_year, month_seq), 0) - 1 AS profit_yoy_growth,
       RANK() OVER (PARTITION BY d_year, month_seq, state ORDER BY total_net_profit DESC) AS category_rank_in_state_month
FROM agg_sales
WHERE total_net_profit > 0
ORDER BY d_year, month_seq, state, category_rank_in_state_month
LIMIT 100
