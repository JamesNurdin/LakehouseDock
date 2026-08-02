/* Goal: Summarize high‑value web sales by item, customer, and shipping mode for selected item classes and costs, while expanding item colour/size attributes via UNNEST. */
WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_ship_mode_sk,
        ws_bill_customer_sk,
        ws_bill_addr_sk,
        ws_bill_cdemo_sk,
        ws_web_page_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price,
        MIN(ws_sales_price) AS min_sales_price,
        MAX(ws_sales_price) AS max_sales_price,
        COUNT(*) AS order_count
    FROM tpcds.web_sales
    WHERE ws_ext_sales_price > 500
    GROUP BY ws_item_sk, ws_ship_mode_sk, ws_bill_customer_sk, ws_bill_addr_sk, ws_bill_cdemo_sk, ws_web_page_sk
)
SELECT
    ws_agg.ws_item_sk,
    i.i_item_id,
    i.i_brand,
    i.i_class,
    i.i_color,
    i.i_size,
    attr,
    sm.sm_type,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    cd.cd_gender,
    wp.wp_url,
    ws_agg.total_quantity,
    ws_agg.total_sales,
    ws_agg.avg_sales_price,
    ws_agg.min_sales_price,
    ws_agg.max_sales_price,
    ws_agg.order_count,
    (
        SELECT SUM(ws2.ws_ext_sales_price)
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_item_sk = ws_agg.ws_item_sk
    ) AS total_sales_all_time,
    ws_agg.total_sales / NULLIF(ws_agg.total_quantity, 0) AS avg_price_per_qty
FROM ws_agg
JOIN tpcds.item i
    ON ws_agg.ws_item_sk = i.i_item_sk
JOIN tpcds.ship_mode sm
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_page wp
    ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.customer c
    ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
    ON ws_agg.ws_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
    ON ws_agg.ws_bill_cdemo_sk = cd.cd_demo_sk
CROSS JOIN UNNEST(array[i.i_color, i.i_size]) AS t(attr)
WHERE i.i_class_id IN (8, 16)
  AND i.i_wholesale_cost > 5.00
  AND wp.wp_link_count >= 10
  AND sm.sm_type = 'AIR'
  AND c.c_preferred_cust_flag = 'Y'
  AND ws_agg.total_sales > 1000
ORDER BY ws_agg.total_sales DESC
LIMIT 100
