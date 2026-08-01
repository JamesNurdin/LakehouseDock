WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_wholesale_cost > 20.00
      AND cs_ext_list_price < 5000.00
      AND cs_quantity >= 1
),

order_intersection AS (
    SELECT cs_order_number
    FROM cs_sample
    WHERE cs_net_profit > 0
    INTERSECT
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_net_profit > 0
      AND cs_sold_date_sk IN (
          SELECT d_date_sk
          FROM date_dim
          WHERE d_year = 2001
      )
),

store_web AS (
    -- Full outer join of store and web_site through date_dim to keep unmatched rows from both sides
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_market_manager,
        s.s_state,
        w.web_site_sk,
        w.web_name,
        w.web_market_manager,
        w.web_state,
        d.d_date_sk
    FROM store s
    FULL OUTER JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    FULL OUTER JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
),

sales_agg AS (
    SELECT
        d.d_year,
        s.s_market_manager,
        w.web_market_manager,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit)      AS total_profit,
        COUNT(*)                  AS cnt_orders
    FROM cs_sample cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
      AND s.s_state = 'CA'
      AND w.web_state = 'CA'
    GROUP BY ROLLUP (d.d_year, s.s_market_manager, w.web_market_manager)
    HAVING SUM(cs.cs_ext_sales_price) > 10000
)
SELECT
    sa.d_year,
    sa.s_market_manager,
    sa.web_market_manager,
    sa.total_sales,
    sa.total_profit,
    sa.cnt_orders
FROM sales_agg sa
WHERE sa.total_sales > (
          SELECT AVG(total_sales)
          FROM sales_agg
      )
  AND sa.cnt_orders > (
          SELECT MAX(cnt_orders)
          FROM sales_agg
          WHERE d_year = 2001
      )
  AND EXISTS (
          SELECT 1
          FROM order_intersection oi
          WHERE oi.cs_order_number = (
              SELECT cs_order_number
              FROM cs_sample
              LIMIT 1
          )
      )
LIMIT 100
