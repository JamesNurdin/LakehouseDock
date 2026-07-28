WITH filtered_sales AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_web_site_sk,
        ws.ws_item_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_hdemo_sk,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        hd.hd_income_band_sk,
        ca.ca_location_type,
        wsit.web_name,
        wsit.web_state,
        wsit.web_gmt_offset
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE i.i_current_price > 20
      AND hd.hd_income_band_sk IN (3, 7, 10)
      AND ca.ca_location_type = 'apartment'
      AND wsit.web_state = 'CA'
)
SELECT
    web_name,
    web_state,
    brand,
    category,
    total_sales,
    order_cnt,
    avg_qty,
    RANK() OVER (PARTITION BY web_name ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        wsit.web_name AS web_name,
        wsit.web_state AS web_state,
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_quantity) AS avg_qty
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE i.i_current_price > 20
      AND hd.hd_income_band_sk IN (3, 7, 10)
      AND ca.ca_location_type = 'apartment'
      AND wsit.web_state = 'CA'
    GROUP BY ROLLUP (wsit.web_name, i.i_brand, i.i_category, wsit.web_state)
    HAVING SUM(ws.ws_ext_sales_price) > 10000
) agg
ORDER BY total_sales DESC
LIMIT 100
