WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        w.w_warehouse_name,
        cs.cs_net_paid_inc_tax,
        cs.cs_ext_list_price,
        cr.cr_return_amount,
        cr.cr_net_loss,
        CASE WHEN cr.cr_return_amount > 100 THEN 'high' ELSE 'low' END AS return_category,
        COUNT(*) OVER (PARTITION BY cs.cs_warehouse_sk) AS warehouse_sales_cnt
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_street_type IN ('Avenue', 'Boulevard')
      AND ca.ca_county = 'Bledsoe County'
      AND cs.cs_net_paid_inc_tax > 500
      AND cs.cs_ext_list_price >= 1000
      AND cr.cr_return_amount > 0
      AND wr.wr_return_amt > 0
)
SELECT
    w_warehouse_name AS warehouse_name,
    return_category,
    SUM(cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(cr_return_amount) AS avg_return_amount,
    SUM(warehouse_sales_cnt) AS total_sales_cnt
FROM sales_returns
GROUP BY w_warehouse_name, return_category
HAVING SUM(cs_net_paid_inc_tax) > 1000
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
