WITH catalog_agg AS (
   SELECT
       cc.cc_call_center_sk,
       cc.cc_manager,
       cc.cc_suite_number,
       SUM(cr.cr_net_loss) AS total_catalog_net_loss,
       COUNT(*) AS catalog_return_cnt
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   WHERE
       td.t_shift = 'Afternoon'
       AND cc.cc_manager LIKE 'J%'
       AND regexp_like(cc.cc_suite_number, '^Suite \d{3}$')
   GROUP BY cc.cc_call_center_sk, cc.cc_manager, cc.cc_suite_number
),

web_return_agg AS (
   SELECT
       ws.ws_web_page_sk,
       SUM(wr.wr_net_loss) AS total_web_net_loss,
       COUNT(*) AS web_return_cnt
   FROM web_returns wr
   JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
   JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
   WHERE
       td.t_shift = 'Afternoon'
       AND regexp_like(CAST(ws.ws_web_page_sk AS varchar), '^[2-3][0-9]{3}$')
   GROUP BY ws.ws_web_page_sk
)

SELECT
   ca.cc_manager,
   ca.cc_suite_number,
   ca.total_catalog_net_loss,
   ca.catalog_return_cnt,
   COALESCE(wr.total_web_net_loss, 0) AS total_web_net_loss,
   COALESCE(wr.web_return_cnt, 0) AS web_return_cnt,
   CONCAT(ca.cc_manager, ' - ', ca.cc_suite_number) AS manager_suite,
   (ca.total_catalog_net_loss - COALESCE(wr.total_web_net_loss, 0)) AS net_loss_diff,
   CASE
       WHEN ca.total_catalog_net_loss > (SELECT AVG(total_catalog_net_loss) FROM catalog_agg) THEN 'Above Avg'
       ELSE 'Below Avg'
   END AS performance_category
FROM catalog_agg ca
LEFT JOIN web_return_agg wr ON wr.ws_web_page_sk = (
    SELECT ws.ws_web_page_sk
    FROM web_sales ws
    JOIN web_returns wr2 ON ws.ws_item_sk = wr2.wr_item_sk
        AND ws.ws_order_number = wr2.wr_order_number
    WHERE ws.ws_sold_date_sk = (
        SELECT MIN(ws2.ws_sold_date_sk) FROM web_sales ws2
    )
    LIMIT 1
)
ORDER BY net_loss_diff DESC
LIMIT 10
