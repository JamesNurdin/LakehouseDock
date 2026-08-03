WITH sampled_sales AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 1
      AND cs_sales_price > 20.0
      AND cs_net_paid > 0
)
SELECT
    ss.cs_order_number,
    cc.cc_name,
    cp.cp_description,
    p.p_promo_name,
    sm.sm_type,
    td.t_hour,
    ca.ca_city,
    hd.hd_buy_potential,
    ss.cs_net_profit,
    (
        SELECT SUM(cr_sub.cr_return_amount)
        FROM tpcds.catalog_returns cr_sub
        WHERE cr_sub.cr_order_number = ss.cs_order_number
    ) AS total_return_amount,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY ss.cs_net_profit DESC) AS profit_state_rank,
    CASE WHEN ss.cs_net_profit > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
FROM sampled_sales ss
JOIN tpcds.call_center cc ON ss.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.promotion p ON ss.cs_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm ON ss.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.time_dim td ON ss.cs_sold_time_sk = td.t_time_sk
JOIN tpcds.customer_address ca ON ss.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.household_demographics hd ON ss.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN tpcds.catalog_returns cr ON ss.cs_order_number = cr.cr_order_number
WHERE cp.cp_department = 'Electronics'
  AND p.p_channel_email = 'N'
  AND sm.sm_carrier = 'FedEx'

UNION DISTINCT

SELECT
    ss2.cs_order_number,
    cc2.cc_name,
    cp2.cp_description,
    p2.p_promo_name,
    sm2.sm_type,
    td2.t_hour,
    ca2.ca_city,
    hd2.hd_buy_potential,
    ss2.cs_net_profit,
    (
        SELECT SUM(cr_sub2.cr_return_amount)
        FROM tpcds.catalog_returns cr_sub2
        WHERE cr_sub2.cr_order_number = ss2.cs_order_number
    ) AS total_return_amount,
    RANK() OVER (PARTITION BY ca2.ca_state ORDER BY ss2.cs_net_profit DESC) AS profit_state_rank,
    CASE WHEN ss2.cs_net_profit > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
FROM sampled_sales ss2
FULL OUTER JOIN tpcds.catalog_returns cr_full ON ss2.cs_order_number = cr_full.cr_order_number
JOIN tpcds.call_center cc2 ON COALESCE(ss2.cs_call_center_sk, cr_full.cr_call_center_sk) = cc2.cc_call_center_sk
JOIN tpcds.catalog_page cp2 ON COALESCE(ss2.cs_catalog_page_sk, cr_full.cr_catalog_page_sk) = cp2.cp_catalog_page_sk
JOIN tpcds.promotion p2 ON ss2.cs_promo_sk = p2.p_promo_sk
JOIN tpcds.ship_mode sm2 ON COALESCE(ss2.cs_ship_mode_sk, cr_full.cr_ship_mode_sk) = sm2.sm_ship_mode_sk
JOIN tpcds.time_dim td2 ON COALESCE(ss2.cs_sold_time_sk, cr_full.cr_returned_time_sk) = td2.t_time_sk
JOIN tpcds.customer_address ca2 ON COALESCE(ss2.cs_bill_addr_sk, cr_full.cr_refunded_addr_sk) = ca2.ca_address_sk
JOIN tpcds.household_demographics hd2 ON COALESCE(ss2.cs_bill_hdemo_sk, cr_full.cr_refunded_hdemo_sk) = hd2.hd_demo_sk
WHERE cp2.cp_department = 'Electronics'
  AND p2.p_channel_email = 'N'
  AND sm2.sm_carrier = 'FedEx'

ORDER BY profit_state_rank ASC, total_return_amount DESC
OFFSET 0
LIMIT 100
