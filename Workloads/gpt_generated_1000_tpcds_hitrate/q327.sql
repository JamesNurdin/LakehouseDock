WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_time_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
        SUM(ss_quantity) AS total_qty
    FROM store_sales
    WHERE ss_quantity > 1                     -- predicate 1
      AND ss_ext_sales_price >= 10            -- predicate 2
      AND ss_sold_time_sk IS NOT NULL         -- predicate 3
    GROUP BY ss_item_sk, ss_sold_time_sk
),
overall_avg AS (
    SELECT AVG(total_sales) AS avg_sales
    FROM ss_agg
),
joined AS (
    SELECT
        i.i_brand,
        i.i_item_id,
        t.t_hour,
        w.w_state,
        ss.total_sales,
        ss.distinct_customers,
        CASE
            WHEN ib.ib_upper_bound > 80000 THEN 'High'
            ELSE 'Low'
        END AS income_level,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COUNT(DISTINCT ca.ca_state) AS distinct_states,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY ss.total_sales DESC) AS brand_rank,
        CASE
            WHEN ss.total_sales > (SELECT avg_sales FROM overall_avg) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS sales_category
    FROM ss_agg ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c
      ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_address ca
      ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN household_demographics hd
      ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN income_band ib
      ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN warehouse w
      ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE i.i_brand_id IN (1001001, 5003002)               -- predicate 4
      AND t.t_hour BETWEEN 8 AND 20                       -- predicate 5
      AND w.w_state = 'NY'                                 -- predicate 6
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_order_number = ws.ws_order_number
            AND ws2.ws_ext_tax > 20
      )                                                   -- predicate 7 (subquery)
    GROUP BY
        i.i_brand,
        i.i_item_id,
        t.t_hour,
        w.w_state,
        ss.total_sales,
        ss.distinct_customers,
        ib.ib_upper_bound
    HAVING COUNT(DISTINCT ws.ws_order_number) > 5
)
SELECT
    i_brand,
    i_item_id,
    t_hour,
    w_state,
    total_sales,
    distinct_customers,
    income_level,
    distinct_orders,
    distinct_states,
    brand_rank,
    sales_category
FROM joined
WHERE brand_rank <= 5
ORDER BY i_brand, total_sales DESC
LIMIT 100
