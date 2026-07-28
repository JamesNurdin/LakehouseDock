WITH joined AS (
    SELECT
        cs.cs_order_number,
        cc.cc_name,
        cp.cp_catalog_page_number,
        w.w_warehouse_name,
        w.w_county,
        p.p_promo_name,
        ca.ca_city AS billing_city,
        cs.cs_net_profit,
        RANK() OVER (PARTITION BY w.w_warehouse_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cp.cp_catalog_page_number IN (7, 14)
      AND cc.cc_state = 'CA'
      AND w.w_county = 'Marshall County'
      AND p.p_response_target = 1
      AND i.inv_quantity_on_hand > 0
      AND cs.cs_sales_price > 100
      AND cs.cs_quantity >= 2
)
SELECT
    cs_order_number,
    cc_name,
    cp_catalog_page_number,
    w_warehouse_name,
    w_county,
    p_promo_name,
    billing_city,
    cs_net_profit,
    profit_rank
FROM joined
WHERE profit_rank <= 5
ORDER BY w_warehouse_name, profit_rank
