WITH inv_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_store_name,
    d.d_year,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_store_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    COUNT(DISTINCT ws.ws_order_number) AS num_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(ca.ca_gmt_offset) AS min_address_gmt_offset,
    MAX(cc.cc_gmt_offset) AS max_call_center_gmt_offset
FROM
    store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
JOIN inv_sample i
    ON i.inv_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
    AND wp.wp_customer_sk = c.c_customer_sk
JOIN web_sales ws
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
WHERE
    d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND ca.ca_country = 'United States'
    AND hd.hd_vehicle_count >= 1
    AND s.s_state = 'CA'
    AND cc.cc_state = 'CA'
    AND s.s_gmt_offset > (
        SELECT MAX(cc2.cc_gmt_offset)
        FROM call_center cc2
        WHERE cc2.cc_state = 'CA'
    )
GROUP BY
    s.s_store_name,
    d.d_year
ORDER BY
    total_store_profit DESC,
    s.s_store_name
LIMIT 100
