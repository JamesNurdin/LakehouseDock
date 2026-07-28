WITH filtered_sales AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_tax,
        ws.ws_net_paid_inc_ship,
        ca.ca_city,
        ca.ca_state,
        ca.ca_gmt_offset,
        ca.ca_suite_number,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_gmt_offset = -5.00
      AND ca.ca_suite_number = 'Suite A   '
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_count >= 3
      AND ws.ws_ext_tax > 100
      AND ws.ws_net_paid_inc_ship < 5000
      AND ws.ws_net_profit > (
          SELECT AVG(ws2.ws_net_profit)
          FROM web_sales ws2
      )
)
SELECT
    ca_city,
    cd_gender,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_profit,
    COUNT(*) AS order_count,
    MIN(ws_ext_tax) AS min_tax,
    MAX(ws_ext_tax) AS max_tax,
    GROUPING(ca_city) AS grp_city,
    GROUPING(cd_gender) AS grp_gender
FROM filtered_sales
GROUP BY ROLLUP (ca_city, cd_gender)
ORDER BY grp_city, grp_gender, total_sales DESC
LIMIT 100
