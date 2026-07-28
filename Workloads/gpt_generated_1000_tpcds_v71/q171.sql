WITH cs_agg AS (
    SELECT
        cs_bill_customer_sk AS cust_sk,
        cs_ship_mode_sk AS ship_mode_sk,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(*) AS cs_order_cnt
    FROM catalog_sales
    WHERE cs_quantity > 1
        AND cs_wholesale_cost > 10
        AND cs_ext_discount_amt < 100
        AND cs_sold_time_sk BETWEEN 10000 AND 20000
    GROUP BY cs_bill_customer_sk, cs_ship_mode_sk
),
ws_agg AS (
    SELECT
        ws_bill_customer_sk AS cust_sk,
        ws_web_site_sk AS site_sk,
        ws_web_page_sk AS page_sk,
        SUM(ws_net_paid) AS ws_total_net_paid,
        COUNT(*) AS ws_order_cnt
    FROM web_sales
    WHERE ws_quantity > 0
        AND ws_sales_price > 20
    GROUP BY ws_bill_customer_sk, ws_web_site_sk, ws_web_page_sk
),
returns_agg AS (
    SELECT
        wr_returning_customer_sk AS cust_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS return_amount_sum
    FROM web_returns
    WHERE wr_return_amt > 0
        AND wr_return_quantity > 0
    GROUP BY wr_returning_customer_sk
)
SELECT
    c.c_customer_id,
    ca.ca_state,
    sm.sm_type,
    cs.total_net_paid,
    ws.ws_total_net_paid,
    r.return_cnt,
    wp.wp_type AS page_type,
    wsit.web_name AS site_name
FROM cs_agg cs
JOIN customer c ON cs.cust_sk = c.c_customer_sk
JOIN ship_mode sm ON cs.ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN ws_agg ws ON ws.cust_sk = c.c_customer_sk
LEFT JOIN web_site wsit ON ws.site_sk = wsit.web_site_sk
LEFT JOIN web_page wp ON ws.page_sk = wp.wp_web_page_sk
LEFT JOIN returns_agg r ON r.cust_sk = c.c_customer_sk
WHERE ca.ca_country = 'United States'
  AND cd.cd_education_status = 'College'
  AND hd.hd_buy_potential = 'High'
  AND sm.sm_type = 'AIR'
  AND wsit.web_country = 'United States'
  AND cs.total_net_paid > (
        SELECT AVG(total_net_paid) FROM cs_agg
    )
ORDER BY cs.total_net_paid DESC
LIMIT 100
