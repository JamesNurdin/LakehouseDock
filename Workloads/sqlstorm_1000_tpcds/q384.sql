SELECT d.d_year,
       s.s_state,
       i.i_category,
       SUM(ss.ss_net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt
FROM store_sales AS ss
JOIN date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store AS s ON ss.ss_store_sk = s.s_store_sk
JOIN item AS i ON ss.ss_item_sk = i.i_item_sk
GROUP BY d.d_year, s.s_state, i.i_category
ORDER BY d.d_year, s.s_state, i.i_category
LIMIT 100
