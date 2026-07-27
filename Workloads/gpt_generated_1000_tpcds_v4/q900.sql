/*
Goal: Analyze combined catalog, store, and web return and sales performance by department, category, state, gender and web page type, comparing Books vs Electronics departments.
*/
WITH base AS (
    SELECT
        cp.cp_department,
        i.i_category,
        s.s_state,
        cd_refunded.cd_gender,
        wp.wp_type,
        cr.cr_return_amount,
        sr.sr_return_amt,
        ws.ws_net_paid,
        ss.ss_ticket_number
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site webs
        ON ws.ws_web_site_sk = webs.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cp.cp_department IN ('Books', 'Electronics')
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
)
SELECT *
FROM (
    SELECT
        cp_department,
        i_category,
        s_state,
        cd_gender,
        wp_type,
        SUM(cr_return_amount)                     AS total_catalog_return_amount,
        SUM(sr_return_amt)                        AS total_store_return_amount,
        SUM(ws_net_paid)                          AS total_web_sales,
        COUNT(DISTINCT ss_ticket_number)          AS store_ticket_cnt,
        COUNT(*)                                  AS transaction_cnt
    FROM base
    WHERE cp_department = 'Books'
    GROUP BY cp_department, i_category, s_state, cd_gender, wp_type

    UNION ALL

    SELECT
        cp_department,
        i_category,
        s_state,
        cd_gender,
        wp_type,
        SUM(cr_return_amount)                     AS total_catalog_return_amount,
        SUM(sr_return_amt)                        AS total_store_return_amount,
        SUM(ws_net_paid)                          AS total_web_sales,
        COUNT(DISTINCT ss_ticket_number)          AS store_ticket_cnt,
        COUNT(*)                                  AS transaction_cnt
    FROM base
    WHERE cp_department = 'Electronics'
    GROUP BY cp_department, i_category, s_state, cd_gender, wp_type
) AS combined
ORDER BY total_catalog_return_amount DESC
LIMIT 100
