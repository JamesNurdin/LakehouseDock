/*
Goal: Analyze sales performance by call center, ship mode, hour, catalog page and brand, including returned amounts, applying multiple selective filters and a correlated subquery, while using a LEFT OUTER JOIN to capture optional return data.
*/
WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_ext_discount_amt > (
        SELECT avg(cs2.cs_ext_discount_amt)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_item_sk = cs.cs_item_sk
    )
    AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_sales cs3
        WHERE cs3.cs_item_sk = cs.cs_item_sk
        GROUP BY cs3.cs_item_sk
        HAVING count(DISTINCT cs3.cs_sold_date_sk) >= 5
    )
)
SELECT
    cc.cc_name,
    sm.sm_carrier,
    td.t_hour,
    cp.cp_catalog_number,
    i.i_brand,
    COUNT(DISTINCT fs.cs_order_number) AS num_orders,
    SUM(fs.cs_net_paid) AS total_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    MAX(fs.cs_net_profit) AS max_net_profit,
    MIN(fs.cs_net_profit) AS min_net_profit
FROM filtered_sales fs
JOIN tpcds.time_dim td
    ON fs.cs_sold_time_sk = td.t_time_sk
JOIN tpcds.call_center cc
    ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm
    ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.item i
    ON fs.cs_item_sk = i.i_item_sk
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = fs.cs_order_number
    AND cr.cr_item_sk = fs.cs_item_sk
WHERE
    td.t_hour BETWEEN 9 AND 17
    AND sm.sm_carrier = 'DHL'
    AND i.i_brand_id = 10
    AND cp.cp_catalog_number IN (8, 17)
    AND cc.cc_state = 'CA'
GROUP BY
    cc.cc_name,
    sm.sm_carrier,
    td.t_hour,
    cp.cp_catalog_number,
    i.i_brand
ORDER BY total_sales DESC
LIMIT 100
