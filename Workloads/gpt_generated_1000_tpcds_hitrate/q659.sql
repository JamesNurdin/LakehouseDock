WITH ss_agg AS (
    SELECT
        ss_sold_time_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_list_price) AS avg_list_price,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_list_price > 50
      AND ss_quantity >= 1
    GROUP BY ss_sold_time_sk
)
SELECT
    t.t_hour,
    t.t_am_pm,
    v.multiplier,
    ss_agg.total_sales * v.multiplier AS scaled_sales,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    SUM(wr.wr_net_loss) AS total_web_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    CASE
        WHEN SUM(cr.cr_net_loss) > 0 THEN 'Catalog Loss'
        ELSE 'Catalog Gain'
    END AS catalog_loss_flag,
    ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS rn
FROM ss_agg
JOIN time_dim t
  ON ss_agg.ss_sold_time_sk = t.t_time_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_time_sk = t.t_time_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_time_sk = t.t_time_sk
CROSS JOIN (SELECT 1 AS multiplier UNION ALL SELECT 2) v
WHERE t.t_hour BETWEEN 10 AND 14
  AND t.t_am_pm = 'PM'
  AND t.t_minute IN (13, 16, 18)
GROUP BY t.t_hour, t.t_am_pm, v.multiplier, ss_agg.total_sales
ORDER BY scaled_sales DESC
LIMIT 100
