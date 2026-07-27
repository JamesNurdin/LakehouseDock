WITH filtered_sales AS (
    SELECT
        ws.ws_bill_cdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity >= 2
      AND ws.ws_ext_sales_price > 500
      AND EXISTS (
          SELECT 1
          FROM tpcds.ship_mode sm
          WHERE sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
            AND sm.sm_type = 'AIR'
      )
)
SELECT
    cd.cd_education_status,
    wp.wp_type,
    COUNT(*) AS order_cnt,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    AVG(fs.ws_net_profit) AS avg_profit,
    MIN(fs.ws_sold_date_sk) AS min_sold_date_sk,
    MAX(fs.ws_sold_date_sk) AS max_sold_date_sk
FROM filtered_sales fs
JOIN tpcds.customer_demographics cd
  ON fs.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.web_page wp
  ON fs.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site wsit
  ON fs.ws_web_site_sk = wsit.web_site_sk
WHERE cd.cd_dep_count <= 2
  AND cd.cd_education_status = '4 yr Degree'
  AND wp.wp_type = 'content'
  AND wsit.web_country = 'United States'
  AND wsit.web_company_id = 1
GROUP BY cd.cd_education_status, wp.wp_type
ORDER BY total_sales DESC
LIMIT 10
