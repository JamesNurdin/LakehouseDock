WITH ss AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_state,
    p.p_promo_name,
    td.t_hour,
    SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS store_sales_amount,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales_amount,
    SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS catalog_sales_amount,
    SUM(
        COALESCE(ss.ss_ext_sales_price, 0) +
        COALESCE(ws.ws_ext_sales_price, 0) +
        COALESCE(cs.cs_ext_sales_price, 0)
    ) AS total_sales,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(ss.ss_net_profit) AS avg_store_profit,
    MIN(ws.ws_net_paid) AS min_web_paid,
    MAX(cs.cs_net_paid) AS max_catalog_paid
FROM ss
FULL OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
LEFT JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_customer_sk = c.c_customer_sk
    AND sr.sr_store_sk = s.s_store_sk
LEFT JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND td.t_hour BETWEEN 9 AND 17
    AND ca.ca_location_type = 'apartment'
    AND we.web_country = 'United States'
GROUP BY
    s.s_state,
    p.p_promo_name,
    td.t_hour
ORDER BY total_sales DESC
LIMIT 100
