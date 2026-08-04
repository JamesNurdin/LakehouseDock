WITH sampled_item AS (
        SELECT *
        FROM item TABLESAMPLE BERNOULLI (10)
    ),
    order_numbers_excluded AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        EXCEPT
        SELECT ws.ws_order_number
        FROM web_sales ws
    )
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    sm.sm_type,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(COALESCE(cs.cs_net_profit, 0)) AS catalog_sales_profit,
    SUM(COALESCE(ss.ss_net_profit, 0)) AS store_sales_profit,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS web_sales_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_returns_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS web_returns_loss,
    AVG(i.i_current_price) AS avg_item_price,
    CASE
        WHEN SUM(COALESCE(cs.cs_net_profit, 0)) > 100000 THEN 'HIGH'
        WHEN SUM(COALESCE(cs.cs_net_profit, 0)) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS catalog_profit_category,
    (SELECT COUNT(*) FROM order_numbers_excluded) AS excluded_order_count
FROM date_dim d
FULL OUTER JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
FULL OUTER JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN sampled_item i
    ON i.i_item_sk = cs.cs_item_sk
LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
LEFT JOIN customer c
    ON c.c_first_shipto_date_sk = d.d_date_sk
LEFT JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2001
  AND i.i_manager_id = 6
  AND cd.cd_purchase_estimate >= 8000
  AND sm.sm_type = 'AIR'
GROUP BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
ORDER BY d.d_year DESC, catalog_sales_profit DESC
LIMIT 100
