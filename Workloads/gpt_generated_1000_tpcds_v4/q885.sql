WITH inv_summary AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    i.i_brand,
    cp.cp_department,
    sm.sm_type AS ship_mode,
    p1.p_promo_name,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    SUM(sr.sr_return_amt)      AS store_returns,
    SUM(wr.wr_return_amt)      AS web_returns,
    SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) AS total_profit,
    inv_sum.total_on_hand
FROM catalog_sales cs
JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer c_wr_returning ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN inv_summary inv_sum ON inv_sum.inv_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_item_sk = cs.cs_item_sk
      AND inv2.inv_quantity_on_hand > 0
)
GROUP BY
    i.i_item_id,
    i.i_category,
    i.i_brand,
    cp.cp_department,
    sm.sm_type,
    p1.p_promo_name,
    inv_sum.total_on_hand
ORDER BY total_profit DESC
LIMIT 100
