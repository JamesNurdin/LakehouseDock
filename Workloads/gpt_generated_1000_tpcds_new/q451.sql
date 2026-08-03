WITH sampled_sr AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
),
sales_without_returns AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
),
base AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        i.i_brand,
        cc.cc_class,
        ws.web_name,
        sm.sm_type,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        l.total_qty_per_order
    FROM sampled_sr sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN sales_without_returns swr ON cs.cs_order_number = swr.cs_order_number
    CROSS JOIN LATERAL (
        SELECT SUM(cs2.cs_quantity) AS total_qty_per_order
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = cs.cs_order_number
    ) AS l
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cc.cc_class = 'large'
      AND ws.web_name = 'Site A'
      AND sm.sm_type = 'AIR'
)
SELECT
    d_year,
    s_state,
    i_category,
    i_brand,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_ext_discount_amt) AS avg_discount,
    MIN(cs_net_paid) AS min_net_paid,
    MAX(cs_net_paid) AS max_net_paid,
    SUM(total_qty_per_order) AS total_quantity
FROM base
GROUP BY d_year, s_state, i_category, i_brand
ORDER BY total_net_paid DESC
OFFSET 10
LIMIT 100
