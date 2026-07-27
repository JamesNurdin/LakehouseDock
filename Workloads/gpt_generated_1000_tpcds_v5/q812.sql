WITH returns_agg AS (
    SELECT
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
        REGEXP_EXTRACT(ca.ca_city, '([A-Za-z]+)') AS city_alpha,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN customer_address ca
      ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE REGEXP_LIKE(ca.ca_city, '^A.*')
      AND wsite.web_name LIKE '%Shop%'
    GROUP BY
        CONCAT(ca.ca_city, ', ', ca.ca_state),
        REGEXP_EXTRACT(ca.ca_city, '([A-Za-z]+)'),
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk
)
SELECT
    city_state,
    city_alpha,
    ws_warehouse_sk,
    ws_web_site_sk,
    total_net_loss,
    return_cnt
FROM returns_agg
ORDER BY total_net_loss DESC
LIMIT 100
