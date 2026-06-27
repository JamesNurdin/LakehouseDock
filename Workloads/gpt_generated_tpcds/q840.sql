/*
  Revenue and profit by hour, shift and AM/PM for typical business hours.
  Shows the top 5 hour‑shift combos ranked by total profit.
*/
WITH ws_time AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid,
        ws.ws_net_profit,
        td.t_hour,
        td.t_shift,
        td.t_am_pm
    FROM web_sales ws
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        t_hour,
        t_shift,
        t_am_pm,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM ws_time
    GROUP BY t_hour, t_shift, t_am_pm
    HAVING SUM(ws_ext_sales_price) > 10000
)
SELECT
    t_hour,
    t_shift,
    t_am_pm,
    total_profit,
    total_sales,
    order_count,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 5
