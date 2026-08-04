WITH order_numbers_excluded AS (
        SELECT cs_order_number FROM catalog_sales
        EXCEPT
        SELECT cr_order_number FROM catalog_returns
    ),
    avg_discount_active AS (
        SELECT AVG(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END) AS avg_active
        FROM promotion
    )
SELECT
    d1.d_year,
    s.s_state,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag,
    LAG(SUM(cs.cs_net_profit)) OVER (PARTITION BY s.s_state ORDER BY d1.d_year) AS lag_state_profit,
    (SELECT avg_active FROM avg_discount_active) AS avg_discount_active_flag,
    (SELECT COUNT(*) FROM order_numbers_excluded) AS orders_without_returns
FROM catalog_sales cs
JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = d1.d_date_sk
FULL OUTER JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d1.d_date_sk
LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
WHERE cs.cs_quantity > 0
GROUP BY d1.d_year, s.s_state
ORDER BY total_net_profit DESC
LIMIT 100
