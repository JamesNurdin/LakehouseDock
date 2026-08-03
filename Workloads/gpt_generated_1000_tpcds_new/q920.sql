WITH filtered_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > 100
      AND i_brand = 'Brand#24'
),
unioned AS (
    SELECT
        cp.cp_department AS cp_department,
        i.i_category AS i_category,
        s.s_state AS s_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(CASE WHEN cs.cs_ext_discount_amt > 0 THEN cs.cs_ext_discount_amt END) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM
        item i
        JOIN filtered_items fi ON i.i_item_sk = fi.i_item_sk
        JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        cp.cp_department = 'Sports'
        AND s.s_state = 'CA'
        AND inv.inv_quantity_on_hand > 100
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
        AND p.p_discount_active = 'Y'
        AND cd.cd_gender = 'M'
    GROUP BY
        cp.cp_department,
        i.i_category,
        s.s_state

    UNION

    SELECT
        cp.cp_department AS cp_department,
        i.i_category AS i_category,
        s.s_state AS s_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(CASE WHEN cs.cs_ext_discount_amt > 0 THEN cs.cs_ext_discount_amt END) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM
        item i
        JOIN filtered_items fi ON i.i_item_sk = fi.i_item_sk
        JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        cp.cp_department = 'Sports'
        AND s.s_state = 'CA'
        AND inv.inv_quantity_on_hand > 100
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
        AND p.p_discount_active = 'Y'
        AND cd.cd_gender = 'M'
    GROUP BY
        cp.cp_department,
        i.i_category,
        s.s_state
)
SELECT
    u.cp_department,
    u.i_category,
    u.s_state,
    u.total_sales,
    u.avg_discount,
    u.distinct_orders,
    CASE WHEN u.total_sales > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
    t.multiplier
FROM
    unioned u
CROSS JOIN (VALUES (1), (2)) AS t(multiplier)
ORDER BY
    u.total_sales DESC
LIMIT 100
