WITH joined AS (
   SELECT
       sr.sr_refunded_cash,
       sr.sr_return_tax,
       sr.sr_store_credit,
       sr.sr_net_loss,
       td.t_meal_time,
       td.t_second,
       w.w_warehouse_name,
       w.w_county,
       w.w_gmt_offset,
       wp.wp_type,
       wp.wp_char_count,
       site.web_state,
       ws.ws_net_profit,
       ws.ws_quantity,
       ws.ws_order_number
   FROM store_returns sr
   JOIN time_dim td
     ON sr.sr_return_time_sk = td.t_time_sk
   JOIN web_sales ws
     ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site site
     ON ws.ws_web_site_sk = site.web_site_sk
   WHERE td.t_meal_time = 'dinner'
     AND sr.sr_refunded_cash > 50
     AND w.w_county = 'Bronx County'
     AND site.web_state = 'CA'
     AND wp.wp_type = 'content'
),
agg_warehouse AS (
   SELECT
       w_warehouse_name,
       w_county,
       SUM(ws_net_profit) AS total_profit,
       SUM(sr_net_loss) AS total_loss,
       COUNT(ws_order_number) AS sales_cnt
   FROM joined
   GROUP BY w_warehouse_name, w_county
)
SELECT
    w_warehouse_name,
    w_county,
    total_profit,
    total_loss,
    sales_cnt,
    total_profit / NULLIF(sales_cnt, 0) AS avg_profit_per_sale,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank,
    CASE 
        WHEN total_profit > (SELECT AVG(total_profit) FROM agg_warehouse) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM agg_warehouse
WHERE total_profit > 1000
  AND total_loss < 5000
ORDER BY total_profit DESC
LIMIT 10
