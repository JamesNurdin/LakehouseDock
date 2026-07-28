WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(cs.cs_net_profit)                      AS total_net_profit,
        SUM(cs.cs_quantity)                        AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number)         AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN store s
      ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN inventory i
      ON i.inv_date_sk = d_sold.d_date_sk
    JOIN web_site w
      ON w.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001                                 -- filter 1: specific year
      AND s.s_country = 'United States'                       -- filter 2: store country
      AND i.inv_quantity_on_hand > 0                          -- filter 3: inventory on hand
      AND t.t_hour >= 9                                        -- filter 4: business hours
    GROUP BY s.s_store_sk, s.s_store_name, d_sold.d_year, d_sold.d_month_seq
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.total_net_profit,
    sa.total_quantity,
    sa.order_cnt,
    RANK() OVER (PARTITION BY sa.d_year, sa.d_month_seq ORDER BY sa.total_net_profit DESC) AS profit_rank,
    SUM(sa.total_net_profit) OVER (PARTITION BY sa.d_year ORDER BY sa.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_year_profit,
    (SELECT AVG(cs2.cs_net_profit)
       FROM catalog_sales cs2
       JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
      WHERE d2.d_year = sa.d_year)                             AS year_avg_profit
FROM sales_agg sa
WHERE NOT EXISTS (
    SELECT 1
    FROM store s_ex
    JOIN date_dim d_ex ON s_ex.s_closed_date_sk = d_ex.d_date_sk
    JOIN inventory i_ex ON i_ex.inv_date_sk = d_ex.d_date_sk
    WHERE s_ex.s_store_sk = sa.s_store_sk
      AND i_ex.inv_quantity_on_hand = 0
)
ORDER BY sa.d_year, sa.d_month_seq, profit_rank
