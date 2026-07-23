WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_order_number
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 0
      AND cs.cs_net_profit > 0
      AND cs.cs_ext_sales_price > 0
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cc.cc_name AS call_center_name,
    ca.ca_city AS customer_city,
    p.p_promo_name,
    t.t_hour,
    SUM(cs_agg.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs_agg.cs_order_number) AS order_count,
    AVG(cs_agg.cs_quantity) AS avg_quantity,
    MAX(cs_agg.cs_ext_sales_price) AS max_sales_price,
    CASE
        WHEN SUM(cs_agg.cs_net_profit) > 100000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS profit_category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS return_count,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_ticket_count
FROM cs_agg
JOIN tpcds.item i ON cs_agg.cs_item_sk = i.i_item_sk
JOIN tpcds.warehouse w ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.customer_address ca ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN tpcds.time_dim t ON cs_agg.cs_sold_time_sk = t.t_time_sk
LEFT JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = cs_agg.cs_item_sk AND cr.cr_order_number = cs_agg.cs_order_number
LEFT JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
WHERE
    p.p_channel_tv = 'N'
    AND w.w_county = 'Daviess County'
    AND t.t_minute IN (14, 15, 16, 17)
    AND i.i_color = 'Red'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cc.cc_name,
    ca.ca_city,
    p.p_promo_name,
    t.t_hour
ORDER BY total_net_profit DESC
LIMIT 100
