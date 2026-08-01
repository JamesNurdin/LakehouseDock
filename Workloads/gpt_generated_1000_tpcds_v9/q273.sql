SELECT
    d.d_year,
    d.d_quarter_name,
    cc.cc_name,
    s.s_state,
    sm.sm_type,
    r.r_reason_desc,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(cs.cs_net_paid) AS min_sales,
    MAX(cs.cs_net_paid) AS max_sales,
    top_reason.top_reason_desc,
    top_reason.top_reason_loss
FROM date_dim d
JOIN call_center cc
  ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
  AND cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_order_number = cs.cs_order_number
  AND cr.cr_call_center_sk = cc.cc_call_center_sk
  AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  AND cr.cr_item_sk = cs.cs_item_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
  ON s.s_store_sk = sr.sr_store_sk
JOIN reason r
  ON r.r_reason_sk = sr.sr_reason_sk
JOIN customer_address ca1
  ON ca1.ca_address_sk = cs.cs_bill_addr_sk
JOIN household_demographics hd1
  ON hd1.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
  ON wp.wp_web_page_sk = wr.wr_web_page_sk
  AND wp.wp_creation_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
    SELECT
        r2.r_reason_desc AS top_reason_desc,
        SUM(sr2.sr_net_loss) AS top_reason_loss
    FROM store_returns sr2
    JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
    WHERE sr2.sr_store_sk = s.s_store_sk
    GROUP BY r2.r_reason_desc
    ORDER BY top_reason_loss DESC
    LIMIT 1
) AS top_reason
WHERE d.d_year = 2000
  AND d.d_quarter_name = '2000Q1'
  AND cc.cc_name = 'Call Center 1'
  AND s.s_state = 'CA'
  AND r.r_reason_desc = 'Customer not satisfied'
  AND sm.sm_type = 'AIR'
  AND wp.wp_char_count > 5000
GROUP BY
    d.d_year,
    d.d_quarter_name,
    cc.cc_name,
    s.s_state,
    sm.sm_type,
    r.r_reason_desc,
    top_reason.top_reason_desc,
    top_reason.top_reason_loss
ORDER BY total_sales DESC
LIMIT 100
