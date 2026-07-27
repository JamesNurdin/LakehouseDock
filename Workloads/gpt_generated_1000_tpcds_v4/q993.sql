WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE p.p_channel_demo = 'N'
      AND p.p_channel_dmail = 'Y'
      AND ca.ca_county = 'Maricopa County'
      AND cc.cc_state = 'CA'
      AND cs.cs_net_paid_inc_ship > 5000
) 
SELECT
    cc.cc_name,
    i.i_category,
    p.p_promo_name,
    COUNT(DISTINCT fs.cs_order_number) AS order_cnt,
    SUM(fs.cs_net_paid_inc_ship) AS total_paid_inc_ship,
    AVG(fs.cs_net_profit) AS avg_profit,
    CASE WHEN SUM(fs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
FROM filtered_sales fs
JOIN tpcds.call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.item i ON fs.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p ON fs.cs_promo_sk = p.p_promo_sk
GROUP BY
    cc.cc_name,
    i.i_category,
    p.p_promo_name
ORDER BY total_paid_inc_ship DESC
LIMIT 100
