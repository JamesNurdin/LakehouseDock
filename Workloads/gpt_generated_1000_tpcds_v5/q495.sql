WITH sales_agg AS (
    SELECT
        i.i_brand,
        i.i_category,
        t.t_hour,
        t.t_am_pm,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        AVG(ss.ss_net_paid_inc_tax) AS avg_store_sale
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_net_paid_inc_tax > 1000
      AND i.i_color = 'Red'
      AND t.t_am_pm = 'PM'
      AND t.t_hour BETWEEN 12 AND 18
    GROUP BY i.i_brand, i.i_category, t.t_hour, t.t_am_pm
),
web_join AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_time_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_order_number,
        i.i_brand,
        i.i_category,
        t.t_hour,
        t.t_am_pm
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_net_paid_inc_tax > 500
      AND i.i_color = 'Red'
      AND t.t_am_pm = 'PM'
      AND t.t_hour BETWEEN 12 AND 18
)
SELECT
    sa.i_brand,
    sa.i_category,
    sa.t_hour,
    sa.t_am_pm,
    sa.total_store_sales,
    sa.store_txn_cnt,
    ROUND(sa.avg_store_sale, 2) AS avg_store_sale,
    SUM(wj.ws_net_paid_inc_tax) AS total_web_sales,
    COUNT(DISTINCT wj.ws_order_number) AS web_order_cnt,
    SUM(cr.cr_net_loss) AS total_return_loss
FROM sales_agg sa
JOIN web_join wj
      ON wj.i_brand = sa.i_brand
     AND wj.i_category = sa.i_category
     AND wj.t_hour = sa.t_hour
     AND wj.t_am_pm = sa.t_am_pm
JOIN catalog_returns cr
      ON cr.cr_item_sk = wj.ws_item_sk
     AND cr.cr_returned_time_sk = wj.ws_sold_time_sk
JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type = 'monthly'
  AND EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
          AND cc.cc_state = 'CA'
      )
GROUP BY sa.i_brand,
         sa.i_category,
         sa.t_hour,
         sa.t_am_pm,
         sa.total_store_sales,
         sa.store_txn_cnt,
         sa.avg_store_sale
ORDER BY sa.total_store_sales DESC
LIMIT 100
