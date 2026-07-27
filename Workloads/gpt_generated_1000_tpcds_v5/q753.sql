SELECT
    ws_site.web_company_id,
    ws_site.web_name,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    CASE WHEN cr.cr_return_tax > 50 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    MIN(ws.ws_ship_date_sk) AS earliest_ship_date_sk,
    MAX(ws.ws_ship_date_sk) AS latest_ship_date_sk
FROM catalog_returns cr
JOIN customer c_refunded
  ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c_refunded.c_customer_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE cr.cr_return_tax > 20.00
  AND cr.cr_return_amt_inc_tax < 2000.00
  AND cr.cr_refunded_cash > 0.00
  AND ws.ws_wholesale_cost BETWEEN 10 AND 70
  AND ws_site.web_company_id IN (1, 3)
  AND ws_site.web_rec_start_date >= DATE '2000-01-01'
  AND p.p_cost > 500
GROUP BY
    ws_site.web_company_id,
    ws_site.web_name,
    CASE WHEN cr.cr_return_tax > 50 THEN 'HighTax' ELSE 'LowTax' END
ORDER BY total_return_amount DESC
LIMIT 100
