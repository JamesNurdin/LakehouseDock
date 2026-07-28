WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        d.d_date,
        i.i_item_id,
        i.i_category,
        c.c_customer_id,
        ca.ca_city,
        s.s_store_name,
        p.p_promo_name,
        cp.cp_catalog_page_id,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        sr.sr_return_quantity,
        r.r_reason_desc,
        wp.wp_url,
        wr.wr_return_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        cs.cs_ext_sales_price AS cat_ext_sales_price,
        cs.cs_net_paid AS cat_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND ca.ca_country = 'United States'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Electronics'
),
agg AS (
    SELECT
        s_store_name,
        d_date,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(inv_quantity_on_hand) AS total_inventory,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_store_returns,
        SUM(COALESCE(wr_return_quantity, 0)) AS total_web_returns,
        COUNT(DISTINCT i_item_id) AS distinct_items_sold
    FROM joined_data
    GROUP BY s_store_name, d_date
    HAVING SUM(ss_ext_sales_price) > 1000
),
catalog_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        d.d_date,
        SUM(cs.cs_ext_sales_price) AS cat_sales,
        SUM(cs.cs_net_paid) AS cat_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'Catalog'
      AND cs.cs_quantity > 0
    GROUP BY cp.cp_catalog_page_id, d.d_date
)
SELECT *
FROM (
    SELECT
        s_store_name AS entity_name,
        d_date,
        total_store_sales AS sales_amount,
        total_store_profit AS profit,
        total_inventory,
        total_store_returns,
        total_web_returns,
        distinct_items_sold
    FROM agg
    UNION ALL
    SELECT
        cp_catalog_page_id AS entity_name,
        d_date,
        cat_sales AS sales_amount,
        NULL AS profit,
        NULL AS total_inventory,
        NULL AS total_store_returns,
        NULL AS total_web_returns,
        NULL AS distinct_items_sold
    FROM catalog_agg
) combined
WHERE sales_amount > (
    SELECT AVG(sales_amount)
    FROM (
        SELECT total_store_sales AS sales_amount FROM agg
        UNION ALL
        SELECT cat_sales FROM catalog_agg
    ) avg_sub
) AND EXISTS (
    SELECT 1 FROM reason r2 WHERE r2.r_reason_desc = 'Damaged'
)
ORDER BY entity_name, d_date DESC
LIMIT 100
