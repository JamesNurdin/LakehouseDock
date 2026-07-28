WITH sales_data AS (
    SELECT
        w.web_site_sk,
        w.web_name,
        w.web_manager,
        ws.ws_net_paid,
        ca.ca_city,
        hd.hd_buy_potential
    FROM web_sales ws
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_city LIKE 'A%'
      AND regexp_like(w.web_manager, '^.*\\bC.*')
      AND w.web_rec_end_date = DATE '2000-08-15'
),
agg AS (
    SELECT
        web_name,
        web_manager,
        hd_buy_potential,
        regexp_extract(web_manager, '\\s+(\\w+)$', 1) AS manager_last_name,
        concat(web_name, ' - ', web_manager) AS site_desc,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_net_paid) AS avg_net_paid,
        CASE WHEN SUM(ws_net_paid) > 1000000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM sales_data
    GROUP BY web_name, web_manager, hd_buy_potential
)
SELECT
    web_name,
    web_manager,
    manager_last_name,
    hd_buy_potential,
    site_desc,
    total_net_paid,
    avg_net_paid,
    sales_category,
    SUM(total_net_paid) OVER (
        ORDER BY total_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_total_net_paid
FROM agg
WHERE manager_last_name LIKE 'C%'
ORDER BY total_net_paid DESC
LIMIT 20
