WITH cc_parts AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        name_part
    FROM call_center cc
    CROSS JOIN UNNEST(split(cc.cc_name, ' ')) AS t(name_part)
)
SELECT
    d.d_year,
    i.i_category,
    ca.ca_state,
    ib.ib_lower_bound,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
    AVG(cr.cr_return_amount) AS avg_catalog_return,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT r.r_reason_sk) AS distinct_return_reasons
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returning_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN cc_parts cpp ON cpp.cc_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = i.i_item_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returning_customer_sk = c.c_customer_sk
WHERE
    d.d_year = 2001
    AND i.i_manufact_id = 86
    AND cc.cc_division = 3
    AND p.p_discount_active = 'Y'
    AND ca.ca_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND ss.ss_net_paid_inc_tax > 1000
    AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_returning_customer_sk = c.c_customer_sk
          AND wr2.wr_net_loss > 500
    )
GROUP BY
    d.d_year,
    i.i_category,
    ca.ca_state,
    ib.ib_lower_bound
ORDER BY
    total_store_sales DESC
LIMIT 100
