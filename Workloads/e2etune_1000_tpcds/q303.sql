WITH return_agg AS (
    SELECT i.i_category AS category,
           sm.sm_type AS ship_type,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(cr.cr_net_loss) AS total_net_loss,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451150
      AND cr.cr_warehouse_sk = 13
    GROUP BY i.i_category, sm.sm_type
),
sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ss.ss_ext_sales_price) AS total_sales_amount,
           SUM(ss.ss_net_profit) AS total_net_profit,
           COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450900 AND 2451150
    GROUP BY i.i_category
)
SELECT r.category,
       r.ship_type,
       r.total_return_amount,
       r.total_net_loss,
       s.total_sales_amount,
       s.total_net_profit,
       (s.total_sales_amount - r.total_return_amount) AS net_sales_after_returns,
       (s.total_net_profit - r.total_net_loss) AS net_profit_after_returns,
       r.return_cnt,
       s.sales_cnt
FROM return_agg r
LEFT JOIN sales_agg s ON r.category = s.category
ORDER BY net_profit_after_returns DESC
LIMIT 50
