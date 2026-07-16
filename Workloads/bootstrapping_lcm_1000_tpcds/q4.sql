SELECT
    d_sales.d_year AS sales_year,
    d_returns.d_year AS return_year,
    s.s_store_name,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    COUNT(DISTINCT cs.cs_order_number) AS num_sales,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(cs.cs_net_paid) - SUM(cr.cr_net_loss) AS net_sales_minus_returns,
    AVG(cs.cs_quantity) AS avg_quantity_per_sale,
    AVG(cr.cr_return_quantity) AS avg_quantity_per_return,
    SUM(CASE WHEN ca_bill.ca_state = 'CA' THEN cs.cs_net_paid ELSE 0 END) AS sales_to_CA,
    SUM(CASE WHEN ca_refund.ca_state = 'CA' THEN cr.cr_net_loss ELSE 0 END) AS returns_from_CA,
    SUM(cs.cs_ext_discount_amt) AS total_discount_given,
    SUM(cs.cs_ext_tax) AS total_tax_collected,
    (SUM(cs.cs_net_paid) - SUM(cs.cs_ext_discount_amt) - SUM(cs.cs_ext_tax)) AS net_revenue_before_tax
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN date_dim d_returns
    ON cr.cr_returned_date_sk = d_returns.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_returns.d_date_sk
GROUP BY
    d_sales.d_year,
    d_returns.d_year,
    s.s_store_name,
    s.s_state
HAVING SUM(cs.cs_net_paid) > 0
ORDER BY total_return_net_loss DESC
LIMIT 100
