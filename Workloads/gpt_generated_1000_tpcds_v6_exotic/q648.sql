WITH joined_all AS (
    SELECT
        cs.cs_net_paid,
        c.c_customer_id,
        d.d_year
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r1 ON cr.cr_reason_sk = r1.r_reason_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
)
SELECT DISTINCT
    customer_id,
    year,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        c_customer_id AS customer_id,
        d_year AS year,
        SUM(cs_net_paid) AS total_sales
    FROM joined_all
    WHERE d_year = 1998
    GROUP BY c_customer_id, d_year
    UNION
    SELECT
        c_customer_id AS customer_id,
        d_year AS year,
        SUM(cs_net_paid) AS total_sales
    FROM joined_all
    WHERE d_year = 1999
    GROUP BY c_customer_id, d_year
) t
ORDER BY total_sales DESC
LIMIT 100
