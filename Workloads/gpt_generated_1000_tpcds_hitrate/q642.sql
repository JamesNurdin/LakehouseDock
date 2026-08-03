WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (5)
)
SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    sr.sr_return_amt,
    i.i_item_id,
    c.c_customer_id,
    ca.ca_city,
    r.r_reason_desc,
    CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag,
    ROW_NUMBER() OVER (ORDER BY cr.cr_order_number) AS rn,
    SUM(cr.cr_return_amount) OVER (PARTITION BY i.i_category) AS category_return_total,
    ws.ws_net_paid,
    ws.ws_net_profit,
    wsite.web_name
FROM catalog_returns cr
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
FULL OUTER JOIN store_returns sr ON sr.sr_returned_date_sk = d_cr.d_date_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN sampled_ws ws ON ws.ws_sold_date_sk = d_cr.d_date_sk
LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE ws.ws_order_number NOT IN (SELECT cr2.cr_order_number FROM catalog_returns cr2)
LIMIT 100
