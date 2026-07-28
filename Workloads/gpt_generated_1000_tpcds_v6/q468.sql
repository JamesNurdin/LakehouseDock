WITH sales_by_item AS (
    SELECT
        i.i_class,
        i.i_brand,
        i.i_item_sk,
        SUM(ws.ws_net_paid_inc_ship) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM tpcds.item i
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    WHERE i.i_size IN ('medium', 'small')
      AND wp.wp_autogen_flag = 'N'
      AND ws.ws_net_paid_inc_ship > 1000
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND EXISTS (
          SELECT 1
          FROM tpcds.web_page wp2
          WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
            AND wp2.wp_type = 'A'
      )
    GROUP BY i.i_class, i.i_brand, i.i_item_sk
),
class_agg AS (
    SELECT
        i_class,
        AVG(total_sales) AS avg_sales_per_item,
        SUM(sales_cnt) AS total_transactions
    FROM sales_by_item
    GROUP BY i_class
)
SELECT
    ca.i_class,
    ca.avg_sales_per_item,
    ca.total_transactions
FROM class_agg ca
WHERE ca.avg_sales_per_item > 2000
ORDER BY ca.avg_sales_per_item DESC
LIMIT 10
