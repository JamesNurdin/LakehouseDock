WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_addr_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
)
SELECT
    c.c_customer_id,
    i.i_product_name,
    cc.cc_name,
    cp.cp_catalog_number,
    sm.sm_type,
    SUM(sb.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT sb.cs_order_number) AS orders_cnt,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY SUM(sb.cs_net_profit) DESC) AS profit_rank_state,
    CASE
        WHEN SUM(sb.cs_net_profit) > 10000 THEN 'HIGH'
        WHEN SUM(sb.cs_net_profit) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM sales_base sb
JOIN customer c
    ON sb.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sb.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON sb.cs_bill_addr_sk = ca.ca_address_sk
JOIN call_center cc
    ON sb.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON sb.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON sb.cs_item_sk = i.i_item_sk
JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
JOIN catalog_returns cr
    ON sb.cs_order_number = cr.cr_order_number
WHERE i.i_current_price > 100
  AND cd.cd_purchase_estimate >= 6000
  AND cc.cc_state = 'CA'
  AND cp.cp_catalog_number IN (5, 8)
GROUP BY
    c.c_customer_id,
    i.i_product_name,
    cc.cc_name,
    cp.cp_catalog_number,
    sm.sm_type,
    cc.cc_state
ORDER BY profit_rank_state, total_net_profit DESC
LIMIT 100
