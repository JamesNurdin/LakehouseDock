WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        d.d_date,
        d.d_year,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        wp.wp_web_page_id,
        SUM(ss.ss_ext_sales_price)                AS total_sales,
        SUM(ss.ss_net_profit)                     AS total_profit,
        SUM(COALESCE(sr.sr_refunded_cash, 0))     AS total_refunds,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
        (SELECT AVG(ss2.ss_sales_price) FROM store_sales ss2) AS avg_sales_price_overall
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk      = sr.sr_item_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
       AND wp.wp_customer_sk    = c.c_customer_sk
    WHERE d.d_year = 2001
      AND ss.ss_sales_price > 10
      AND ss.ss_quantity >= 2
      AND ca.ca_city LIKE 'Jackson%'
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'A'
      AND wp.wp_type = 'Home'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        d.d_date,
        d.d_year,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        wp.wp_web_page_id
    HAVING SUM(ss.ss_ext_sales_price) > 500
)
SELECT
    s.c_customer_id,
    s.d_date,
    s.total_sales,
    s.total_profit,
    s.total_refunds,
    s.sales_category,
    s.avg_sales_price_overall,
    RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank_year,
    SUM(s.total_sales) OVER (
        PARTITION BY s.c_customer_sk
        ORDER BY s.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales
FROM sales_agg s
ORDER BY s.total_sales DESC
LIMIT 100
