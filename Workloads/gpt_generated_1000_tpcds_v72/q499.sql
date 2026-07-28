WITH sales_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders_count
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE i.i_category = 'Sports'
      AND ca.ca_country = 'United States'
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_state = 'CA'
    GROUP BY c.c_customer_id, i.i_category
)
SELECT
    COALESCE(customer_id, 'ALL_CUSTOMERS') AS customer_id,
    COALESCE(category, 'ALL_CATEGORIES') AS category,
    SUM(total_sales) AS sum_sales,
    SUM(total_quantity) AS sum_quantity,
    AVG(total_sales) AS avg_sales_per_customer,
    COUNT(*) AS num_groups
FROM sales_agg sa
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    JOIN customer c2 ON cr2.cr_refunded_customer_sk = c2.c_customer_sk
    WHERE c2.c_customer_id = sa.customer_id
)
GROUP BY ROLLUP (customer_id, category)
LIMIT 100
