WITH joined_data AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        cc.cc_division,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        t.t_hour,
        cs.cs_ext_sales_price               AS catalog_sales_amount,
        cs.cs_net_profit                    AS catalog_profit,
        ss.ss_ext_sales_price               AS store_sales_amount,
        ss.ss_net_profit                    AS store_profit,
        wr.wr_return_amt                    AS web_return_amount,
        wr.wr_net_loss                      AS web_return_loss,
        wp.wp_type
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE t.t_hour BETWEEN 8 AND 16                 -- filter 1: business hours
      AND w.w_state = 'CA'                         -- filter 2: specific state
      AND cc.cc_division = 1                       -- filter 3: division
      AND EXISTS (
            SELECT 1
            FROM web_page wp_sub
            WHERE wp_sub.wp_type = 'Home'
              AND wp_sub.wp_web_page_sk = wr.wr_web_page_sk
        )
),
agg AS (
    SELECT
        cc_call_center_id,
        t_hour,
        SUM(COALESCE(catalog_sales_amount, 0) + COALESCE(store_sales_amount, 0) - COALESCE(web_return_amount, 0)) AS net_sales,
        SUM(COALESCE(catalog_profit, 0) + COALESCE(store_profit, 0) - COALESCE(web_return_loss, 0)) AS net_profit
    FROM joined_data
    GROUP BY ROLLUP(cc_call_center_id, t_hour)
),
final AS (
    SELECT
        cc_call_center_id,
        t_hour,
        net_sales,
        net_profit,
        AVG(net_sales) OVER (PARTITION BY t_hour)               AS avg_sales_per_hour,
        ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY net_sales DESC) AS sales_rank
    FROM agg
)
SELECT
    cc_call_center_id,
    t_hour,
    net_sales,
    net_profit,
    avg_sales_per_hour,
    sales_rank
FROM final
WHERE (net_sales > 20000 OR net_profit > 10000)      -- post‑aggregation filter
  AND t_hour IS NOT NULL                               -- drop the grand‑total row from ROLLUP
ORDER BY net_sales DESC
LIMIT 100
