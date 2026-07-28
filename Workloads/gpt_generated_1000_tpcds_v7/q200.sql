WITH joined_data AS (
    SELECT
        c.c_customer_id AS customer_id,
        ca.ca_state AS ca_state,
        ss.ss_net_paid AS store_net_paid,
        cs.cs_net_paid AS catalog_net_paid,
        cr.cr_refunded_cash AS refund_cash,
        d.d_year
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND c.c_birth_country = 'MEXICO'
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
)
SELECT
    customer_id,
    ca_state,
    ROUND(
        SUM(store_net_paid) +
        SUM(catalog_net_paid) -
        COALESCE(SUM(refund_cash), 0),
        2
    ) AS total_sales,
    ROW_NUMBER() OVER (
        PARTITION BY ca_state
        ORDER BY SUM(store_net_paid) + SUM(catalog_net_paid) - COALESCE(SUM(refund_cash), 0) DESC
    ) AS sales_rank
FROM joined_data
GROUP BY customer_id, ca_state
ORDER BY total_sales DESC
LIMIT 100
