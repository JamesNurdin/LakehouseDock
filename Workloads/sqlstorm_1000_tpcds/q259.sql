WITH dim_month AS (
    SELECT d_date_sk,
           date_format(d_date, '%Y-%m') AS month,
           d_year
    FROM date_dim
    WHERE d_year IN (2000, 2001)
),
sales_agg AS (
    SELECT i.i_category AS category,
           dm.month,
           sum(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN dim_month dm ON ss.ss_sold_date_sk = dm.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_category, dm.month

    UNION ALL

    SELECT i.i_category AS category,
           dm.month,
           sum(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN dim_month dm ON cs.cs_sold_date_sk = dm.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, dm.month

    UNION ALL

    SELECT i.i_category AS category,
           dm.month,
           sum(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN dim_month dm ON ws.ws_sold_date_sk = dm.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_category, dm.month
),
sales_sum AS (
    SELECT category, month, sum(net_profit) AS net_profit
    FROM sales_agg
    GROUP BY category, month
),
returns_agg AS (
    SELECT i.i_category AS category,
           dm.month,
           sum(sr.sr_refunded_cash) AS refunded_cash
    FROM store_returns sr
    JOIN dim_month dm ON sr.sr_returned_date_sk = dm.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category, dm.month

    UNION ALL

    SELECT i.i_category AS category,
           dm.month,
           sum(cr.cr_refunded_cash) AS refunded_cash
    FROM catalog_returns cr
    JOIN dim_month dm ON cr.cr_returned_date_sk = dm.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category, dm.month

    UNION ALL

    SELECT i.i_category AS category,
           dm.month,
           sum(wr.wr_refunded_cash) AS refunded_cash
    FROM web_returns wr
    JOIN dim_month dm ON wr.wr_returned_date_sk = dm.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_category, dm.month
),
returns_sum AS (
    SELECT category, month, sum(refunded_cash) AS total_refunded_cash
    FROM returns_agg
    GROUP BY category, month
),
combined AS (
    SELECT s.category,
           s.month,
           s.net_profit - coalesce(r.total_refunded_cash, 0) AS net_profit_adj
    FROM sales_sum s
    LEFT JOIN returns_sum r
      ON s.category = r.category AND s.month = r.month
),
final AS (
    SELECT category,
           month,
           net_profit_adj,
           rank() OVER (PARTITION BY month ORDER BY net_profit_adj DESC) AS month_category_rank,
           lag(net_profit_adj) OVER (PARTITION BY category ORDER BY month) AS prev_month_profit,
           round(
               (net_profit_adj - lag(net_profit_adj) OVER (PARTITION BY category ORDER BY month))
               / nullif(lag(net_profit_adj) OVER (PARTITION BY category ORDER BY month), 0) * 100,
               2) AS month_over_month_pct,
           round(
               avg(net_profit_adj) OVER (PARTITION BY category ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
               2) AS three_month_moving_avg
    FROM combined
    WHERE month BETWEEN '2001-01' AND '2001-12'
)
SELECT *
FROM final
ORDER BY month, month_category_rank
LIMIT 100
