WITH filtered_sales AS (
    SELECT *
    FROM store_sales
    WHERE ss_ext_wholesale_cost > 500
      AND ss_ext_tax BETWEEN 1 AND 200
      AND ss_quantity >= 2
      AND ss_item_sk IN (
          SELECT ss_item_sk
          FROM store_sales
          WHERE ss_ext_sales_price > 1000
          GROUP BY ss_item_sk
          HAVING SUM(ss_quantity) > 10
      )
),
joined AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_tax,
        t.t_shift,
        t.t_hour,
        t.t_am_pm
    FROM filtered_sales AS ss
    JOIN time_dim AS t
      ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_shift = 'first'
      AND t.t_am_pm = 'PM'
),
agg AS (
    SELECT
        t_shift,
        t_hour,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_store_sk) AS distinct_stores
    FROM joined
    GROUP BY t_shift, t_hour
)
SELECT
    t_shift,
    t_hour,
    total_profit,
    total_sales,
    distinct_stores,
    RANK() OVER (PARTITION BY t_shift ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank, t_hour
LIMIT 100
