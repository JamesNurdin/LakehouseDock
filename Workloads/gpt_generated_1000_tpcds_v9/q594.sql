WITH cs_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_bill_addr_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 1
    GROUP BY cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_bill_addr_sk
)
SELECT
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_promo_name,
    ca_bill.ca_state,
    wp.wp_type,
    cs_agg.order_cnt,
    cs_agg.total_quantity,
    cs_agg.total_sales,
    cs_agg.total_profit,
    RANK() OVER (PARTITION BY cc.cc_name ORDER BY cs_agg.total_profit DESC) AS profit_rank,
    SUM(cs_agg.total_profit) OVER (PARTITION BY sm.sm_type) AS profit_by_ship_type
FROM cs_agg
JOIN tpcds.call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN tpcds.customer_address ca_bill
    ON cs_agg.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.web_returns wr
    ON wr.wr_refunded_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    cc.cc_state = 'TX'
    AND sm.sm_type = 'OVERNIGHT'
    AND wp.wp_rec_end_date BETWEEN DATE '2001-09-02' AND DATE '2001-09-03'
ORDER BY cs_agg.total_profit DESC
LIMIT 100
