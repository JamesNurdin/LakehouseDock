WITH returns_agg AS (
    SELECT
        cr_order_number,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cr_reason_sk = 5
      AND cr_fee > 0
      AND cr_return_ship_cost < 50
    GROUP BY cr_order_number
)
SELECT
    w.w_warehouse_name,
    cp.cp_department,
    p.p_promo_name,
    ca_bill.ca_state AS billing_state,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(ra.total_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    AVG(cs.cs_quantity) AS avg_quantity
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN returns_agg ra
    ON cs.cs_order_number = ra.cr_order_number
WHERE cp.cp_type = 'monthly'
  AND w.w_state = 'CA'
  AND p.p_channel_email = 'Y'
  AND ca_bill.ca_state = 'TX'
  AND cs.cs_quantity > 5
  AND cs.cs_net_profit > 0
  AND cs.cs_sold_date_sk = 2450050
GROUP BY
    w.w_warehouse_name,
    cp.cp_department,
    p.p_promo_name,
    ca_bill.ca_state
ORDER BY total_sales DESC
LIMIT 100
