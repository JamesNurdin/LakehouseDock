WITH
    store_agg AS (
        SELECT td.t_hour,
               SUM(ss.ss_net_profit) AS store_profit
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    combined AS (
        SELECT td.t_hour,
               w.w_state,
               SUM(cs.cs_ext_sales_price) AS sales,
               0 AS returns
        FROM catalog_sales cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        GROUP BY td.t_hour, w.w_state
        UNION ALL
        SELECT td.t_hour,
               w.w_state,
               0 AS sales,
               SUM(cr.cr_return_amount) AS returns
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        GROUP BY td.t_hour, w.w_state
    ),
    full_join AS (
        SELECT COALESCE(sa.t_hour, ca.t_hour) AS hour,
               ca.w_state,
               sa.store_profit,
               ca.sales,
               ca.returns
        FROM store_agg sa
        FULL OUTER JOIN combined ca
            ON sa.t_hour = ca.t_hour
    )
SELECT hour,
       w_state,
       SUM(store_profit) AS total_store_profit,
       SUM(sales) AS total_sales,
       SUM(returns) AS total_returns,
       (SUM(sales) - SUM(returns)) AS net_sales
FROM full_join
GROUP BY GROUPING SETS (
    (hour, w_state),
    (hour),
    ()
)
ORDER BY net_sales DESC
LIMIT 100
