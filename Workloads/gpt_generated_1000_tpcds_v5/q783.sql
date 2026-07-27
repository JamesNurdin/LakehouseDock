SELECT
    cc.cc_name,
    w.w_warehouse_name,
    p.p_promo_name,
    ca.ca_state,
    hd.hd_buy_potential,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    AVG(ws.ws_sales_price) AS avg_web_sales_price,
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) AS net_profit_adjusted
FROM tpcds.call_center cc
JOIN tpcds.catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE cc.cc_state = 'CA'
  AND cs.cs_sold_date_sk BETWEEN 2451400 AND 2451500
  AND p.p_discount_active = 'Y'
  AND w.w_warehouse_sq_ft > 500000
  AND ws.ws_sales_price > 50.00
  AND i.inv_date_sk = 2450822
GROUP BY
    cc.cc_name,
    w.w_warehouse_name,
    p.p_promo_name,
    ca.ca_state,
    hd.hd_buy_potential
ORDER BY total_catalog_sales DESC
LIMIT 100
