WITH customer_store_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt
    FROM
        store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        ss.ss_quantity >= 5
        AND ss.ss_net_paid > 100
        AND sr.sr_fee > 10.00
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_sk,
        p.p_promo_name
),
catalog_agg AS (
    SELECT
        c.c_customer_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_quantity) AS total_catalog_quantity
    FROM
        catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        cs.cs_quantity >= 3
        AND p.p_response_target = 1
        AND sm.sm_contract = 'Ek'
    GROUP BY
        c.c_customer_sk
),
web_return_flag AS (
    SELECT
        c.c_customer_sk,
        CASE WHEN EXISTS (
            SELECT 1
            FROM web_returns wr
            JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
            WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
              AND wp.wp_char_count >= 1000
        ) THEN 1 ELSE 0 END AS has_high_char_web_return
    FROM
        customer c
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.p_promo_name,
    SUM(cs.total_store_sales) AS sum_store_sales,
    AVG(cs.total_store_quantity) AS avg_store_quantity,
    SUM(cs.store_ticket_cnt) AS total_store_tickets,
    COALESCE(ca.total_catalog_sales, 0) AS sum_catalog_sales,
    COALESCE(ca.total_catalog_quantity, 0) AS sum_catalog_quantity,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.p_promo_sk
    ) AS max_promo_cost,
    wrf.has_high_char_web_return
FROM
    customer_store_agg cs
    LEFT JOIN catalog_agg ca ON cs.c_customer_sk = ca.c_customer_sk
    LEFT JOIN web_return_flag wrf ON cs.c_customer_sk = wrf.c_customer_sk
GROUP BY
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.p_promo_name,
    cs.p_promo_sk,
    ca.total_catalog_sales,
    ca.total_catalog_quantity,
    wrf.has_high_char_web_return
HAVING
    SUM(cs.total_store_sales) > 2000
ORDER BY
    sum_store_sales DESC
LIMIT 100
