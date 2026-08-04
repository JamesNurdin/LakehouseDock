WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
web_sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        ws.ws_quantity
    FROM web_sales ws
    WHERE ws.ws_sales_price > 20.00
)
SELECT
    s.s_store_name,
    wsite.web_name,
    COUNT(DISTINCT c.c_customer_id)               AS distinct_customers,
    COUNT(DISTINCT wp.wp_url)                     AS distinct_web_pages,
    SUM(ss.ss_net_paid)                           AS total_store_net_paid,
    SUM(ws_agg.ws_net_paid)                       AS total_web_net_paid,
    AVG(ss.ss_quantity)                           AS avg_store_quantity,
    AVG(ws_agg.ws_quantity)                       AS avg_web_quantity,
    SUM(cr.cr_return_amount)                      AS total_return_amount,
    MIN(cr.cr_return_amount)                      AS min_return_amount,
    MAX(cr.cr_return_amount)                      AS max_return_amount,
    SUM(wr.wr_return_amt)                         AS total_web_return_amount
FROM sampled_store_sales ss
INNER JOIN time_dim td_ss
        ON ss.ss_sold_time_sk = td_ss.t_time_sk
INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
/* Join to Web Sales via matching time dimension */
INNER JOIN web_sales_agg ws_agg
        ON ws_agg.ws_sold_time_sk = td_ss.t_time_sk
INNER JOIN ship_mode sm_ws
        ON ws_agg.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
INNER JOIN web_page wp
        ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN web_site wsite
        ON ws_agg.ws_web_site_sk = wsite.web_site_sk
/* Join Catalog Returns that happened at the same time */
INNER JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td_ss.t_time_sk
INNER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
/* Join Web Returns linked to the same order */
INNER JOIN web_returns wr
        ON wr.wr_order_number = ws_agg.ws_order_number
INNER JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
INNER JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE
    s.s_state = 'CA'                                          -- filter 1
    AND wsite.web_state = 'CA'                                 -- filter 2
    AND c.c_customer_id IN (                                   -- filter 3 (IN subquery)
        SELECT c2.c_customer_id
        FROM customer c2
        WHERE c2.c_birth_country = 'United States'
        LIMIT 10
    )
    AND EXISTS (                                               -- filter 4 (EXISTS subquery)
        SELECT 1
        FROM catalog_page cp_sub
        WHERE cp_sub.cp_type = 'monthly'
          AND cp_sub.cp_catalog_page_sk = cr.cr_catalog_page_sk
    )
GROUP BY
    s.s_store_name,
    wsite.web_name
ORDER BY
    total_store_net_paid DESC
LIMIT 100
