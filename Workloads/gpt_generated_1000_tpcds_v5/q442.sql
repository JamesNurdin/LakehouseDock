WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE c.c_birth_year >= 1950
      AND c.c_first_sales_date_sk BETWEEN 2450000 AND 2455000
      AND wsite.web_zip = '33604'
      AND wsite.web_tax_percentage >= 0.05
      AND wp.wp_type = 'ad'
      AND ib.ib_upper_bound <= 80000
      AND wp.wp_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ib_lower_bound,
    ib_upper_bound,
    (store_net_paid + web_net_paid) AS total_net_paid,
    CASE WHEN (store_net_paid + web_net_paid) >= 10000 THEN 'High' ELSE 'Low' END AS spending_category,
    RANK() OVER (ORDER BY (store_net_paid + web_net_paid) DESC) AS sales_rank
FROM base
ORDER BY sales_rank
LIMIT 100
