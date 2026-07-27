WITH ss_agg AS (
    SELECT ss_cdemo_sk,
           SUM(ss_ext_sales_price) AS ss_sum_ext_sales,
           SUM(ss_net_paid) AS ss_sum_net_paid,
           COUNT(*) AS ss_cnt
    FROM store_sales
    WHERE ss_ext_list_price > 500
    GROUP BY ss_cdemo_sk
)
SELECT
    w.w_warehouse_name,
    ws.ws_order_number,
    cd.cd_gender,
    site.web_name,
    wp.wp_type,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_web_ext_sales,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    ss_agg.ss_sum_ext_sales,
    ss_agg.ss_cnt
FROM web_sales ws
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ss_agg
  ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Good'
  AND cd.cd_marital_status = 'M'
  AND w.w_state = 'CA'
  AND site.web_mkt_id = 3
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_item_sk = ws.ws_item_sk
          AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
      )
GROUP BY w.w_warehouse_name,
         ws.ws_order_number,
         cd.cd_gender,
         site.web_name,
         wp.wp_type,
         ss_agg.ss_sum_ext_sales,
         ss_agg.ss_cnt
ORDER BY total_web_net_paid DESC
LIMIT 100
