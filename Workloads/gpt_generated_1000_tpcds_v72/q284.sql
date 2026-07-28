WITH
store_sales_data AS (
    SELECT
        d.d_date AS sale_date,
        ss.ss_net_paid AS sale_amount,
        'store' AS sales_source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year = 2001
        AND s.s_state = 'CA'
        AND i.i_color = 'Red'
        AND c.c_preferred_cust_flag = 'Y'
        AND r.r_reason_desc LIKE '%damage%'
),
catalog_sales_data AS (
    SELECT
        d.d_date AS sale_date,
        cs.cs_net_paid AS sale_amount,
        'catalog' AS sales_source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND cc.cc_state = 'CA'
        AND i.i_size = 'MEDIUM'
        AND cust.c_birth_country = 'United States'
        AND cp.cp_type = 'Catalog'
        AND inv.inv_quantity_on_hand > 0
),
web_sales_data AS (
    SELECT
        d.d_date AS sale_date,
        ws.ws_net_paid AS sale_amount,
        'web' AS sales_source
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        d.d_year = 2001
        AND wsite.web_class = 'Unknown'
        AND i.i_color = 'Red'
        AND wp.wp_type = 'Home'
        AND cust.c_preferred_cust_flag = 'Y'
)
SELECT
    sale_date,
    sales_source,
    sale_amount,
    ROW_NUMBER() OVER (PARTITION BY sales_source ORDER BY sale_amount DESC) AS rank_within_source,
    DENSE_RANK() OVER (ORDER BY sale_amount DESC) AS overall_rank
FROM (
    SELECT * FROM store_sales_data
    UNION ALL
    SELECT * FROM catalog_sales_data
    UNION ALL
    SELECT * FROM web_sales_data
) AS combined
ORDER BY sale_amount DESC
LIMIT 100
