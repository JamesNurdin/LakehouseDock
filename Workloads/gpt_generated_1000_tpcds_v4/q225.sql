WITH item_avg_price AS (
    SELECT i_item_sk, AVG(i_current_price) AS avg_price
    FROM item
    GROUP BY i_item_sk
),
customer_sales AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        i.i_brand,
        cs.cs_net_paid_inc_tax AS catalog_net,
        ss.ss_net_paid_inc_tax AS store_net,
        ws.ws_net_paid_inc_tax AS web_net,
        cs.cs_sold_date_sk,
        ss.ss_sold_date_sk,
        ws.ws_sold_date_sk,
        sm.sm_type,
        cp.cp_department,
        ws.ws_quantity,
        i.i_current_price,
        a.avg_price,
        td.t_hour,
        wp.wp_autogen_flag
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_time_sk = td.t_time_sk
        AND ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN item_avg_price a ON a.i_item_sk = i.i_item_sk
    WHERE cs.cs_net_paid_inc_tax > 1000
      AND ss.ss_quantity BETWEEN 1 AND 5
      AND ws.ws_quantity > 0
      AND i.i_brand = 'Brand#12'
      AND sm.sm_type = 'AIR'
      AND td.t_hour BETWEEN 8 AND 17
      AND wp.wp_autogen_flag = 'Y'
)
SELECT
    c_customer_id,
    i_brand,
    SUM(catalog_net + store_net + web_net) AS total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY SUM(catalog_net + store_net + web_net) DESC) AS rn,
    CASE WHEN SUM(catalog_net) > 5000 THEN 'HIGH_CAT' ELSE 'LOW_CAT' END AS cat_sales_category,
    (SELECT MAX(i_current_price) FROM item WHERE i_brand = customer_sales.i_brand) AS max_brand_price
FROM customer_sales
GROUP BY c_customer_id, i_brand
HAVING SUM(catalog_net + store_net + web_net) > 2000
ORDER BY total_net_paid DESC
LIMIT 100
