WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        i.i_category AS category,
        w.w_state AS warehouse_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND ca.ca_state = 'TX'
        AND cd.cd_gender = 'F'
        AND w.w_gmt_offset = -6.00
        AND p.p_discount_active = 'Y'
        AND i.i_brand_id IN (101, 102)
    GROUP BY cs.cs_sold_date_sk, i.i_category, w.w_state
),
returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        i.i_category AS category,
        s.s_state AS store_state,
        SUM(sr.sr_return_amt) AS total_return,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
        AND r.r_reason_desc LIKE '%size%'
        AND ca.ca_zip = '90419'
        AND cd.cd_marital_status = 'M'
        AND i.i_color = 'Red'
    GROUP BY sr.sr_returned_date_sk, i.i_category, s.s_state
),
inventory_agg AS (
    SELECT
        inv.inv_date_sk AS date_sk,
        i.i_category AS category,
        w.w_state AS warehouse_state,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_state = 'NY'
        AND i.i_category = 'Electronics'
        AND inv.inv_quantity_on_hand > 0
        AND inv.inv_date_sk BETWEEN 2450000 AND 2451000
        AND w.w_gmt_offset = -5.00
        AND i.i_brand = 'BrandX'
    GROUP BY inv.inv_date_sk, i.i_category, w.w_state
),
web_returns_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        i.i_category AS category,
        SUM(wr.wr_return_amt) AS total_web_return,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND wp.wp_type = 'Home'
        AND c.c_preferred_cust_flag = 'Y'
        AND ca.ca_zip = '98579'
        AND cd.cd_education_status = 'College'
        AND i.i_size = 'M'
    GROUP BY wr.wr_returned_date_sk, i.i_category, wp.wp_type
)
SELECT
    date_sk,
    category,
    SUM(total_sales) AS total_sales,
    SUM(total_return) AS total_return,
    SUM(total_on_hand) AS total_on_hand,
    SUM(total_web_return) AS total_web_return
FROM (
    SELECT date_sk, category, total_sales, NULL AS total_return, NULL AS total_on_hand, NULL AS total_web_return FROM sales_agg
    UNION ALL
    SELECT date_sk, category, NULL, total_return, NULL, NULL FROM returns_agg
    UNION ALL
    SELECT date_sk, category, NULL, NULL, total_on_hand, NULL FROM inventory_agg
    UNION ALL
    SELECT date_sk, category, NULL, NULL, NULL, total_web_return FROM web_returns_agg
) u
GROUP BY date_sk, category
HAVING SUM(total_sales) > 10000
    OR SUM(total_return) > 5000
    OR SUM(total_web_return) > 2000
ORDER BY date_sk DESC
LIMIT 100
