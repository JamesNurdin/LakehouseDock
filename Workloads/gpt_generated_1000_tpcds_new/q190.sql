WITH sales_fact AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ss.ss_net_paid,
        ss.ss_quantity
    FROM store_sales ss
    WHERE ss.ss_store_sk IN (
        SELECT s.s_store_sk
        FROM store s
        WHERE s.s_state = 'CA'
    )
)
SELECT
    s.s_store_name,
    d.d_date,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    p.p_promo_name,
    wp.wp_url,
    cp.cp_department,
    ss_fact.ss_net_profit,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY ss_fact.ss_net_profit DESC) AS profit_rank,
    SUM(ss_fact.ss_net_profit) OVER (
        PARTITION BY s.s_store_name
        ORDER BY d.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit
FROM sales_fact ss_fact
JOIN date_dim d ON ss_fact.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss_fact.ss_store_sk = s.s_store_sk
JOIN customer c ON ss_fact.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss_fact.ss_addr_sk = ca.ca_address_sk
JOIN promotion p ON ss_fact.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ss_fact.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss_fact.ss_hdemo_sk = hd.hd_demo_sk
JOIN time_dim t ON ss_fact.ss_sold_time_sk = t.t_time_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND p.p_channel_email = 'Y'
  AND ca.ca_suite_number IN ('Suite 470', 'Suite 480')
  AND wp.wp_type = 'content'
ORDER BY s.s_store_name, profit_rank
LIMIT 100
