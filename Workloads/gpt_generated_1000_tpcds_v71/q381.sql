WITH sales_joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cc.cc_name,
        cp.cp_catalog_page_number,
        sm.sm_type,
        w.w_warehouse_name,
        i.inv_quantity_on_hand,
        r.r_reason_desc,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_net_paid DESC) AS purchase_rank
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND hd.hd_buy_potential = '>10000'
      AND ca.ca_state = 'TX'
      AND w.w_state = 'WA'
      AND r.r_reason_desc = 'Damaged'
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    cs_order_number,
    cs_sold_date_sk,
    cs_net_paid,
    cs_net_profit,
    cc_name,
    cp_catalog_page_number,
    sm_type,
    w_warehouse_name,
    inv_quantity_on_hand,
    r_reason_desc,
    purchase_rank
FROM sales_joined
WHERE purchase_rank = 1
ORDER BY cs_net_paid DESC
LIMIT 100
