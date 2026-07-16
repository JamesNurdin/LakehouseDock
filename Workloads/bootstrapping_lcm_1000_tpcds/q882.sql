SELECT
    cc.cc_company_name,
    cc.cc_manager,
    cc.cc_market_manager,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT wp.wp_url) AS distinct_web_pages,
    MIN(open_date.d_date) AS call_center_open_date,
    MAX(access_date.d_date) AS web_page_latest_access_date
FROM date_dim d
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN date_dim open_date
    ON cc.cc_open_date_sk = open_date.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_store_sk = s.s_store_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN date_dim access_date
    ON wp.wp_access_date_sk = access_date.d_date_sk
GROUP BY
    cc.cc_company_name,
    cc.cc_manager,
    cc.cc_market_manager,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
