WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_ext_ship_cost,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ws.ws_ext_ship_cost,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        w.w_state,
        sm.sm_type,
        cc.cc_company_name,
        ca.ca_state,
        cd.cd_gender,
        wp.wp_type,
        sr.sr_reason_sk
    FROM
        date_dim d
        LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN item i ON i.i_item_sk = cs.cs_item_sk
        LEFT JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
        LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
        LEFT JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
        LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
        LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk AND s.s_store_sk = sr.sr_store_sk
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_order_number = cs.cs_order_number
        LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_year = 2001
        AND i.i_category = 'Sports'
        AND w.w_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND ca.ca_state = 'TX'
        AND cd.cd_gender = 'F'
        AND cc.cc_company_name = 'Company#1'
),

daily_category AS (
    SELECT
        d_date,
        i_category,
        SUM(cs_net_paid_inc_tax) AS cat_sales,
        SUM(ws_net_paid_inc_tax) AS web_sales,
        SUM(sr_net_loss) AS store_return_loss,
        SUM(cr_return_amount) AS catalog_return_amount,
        COUNT(DISTINCT i_item_id) AS distinct_items_sold,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(*) AS transaction_count
    FROM
        base
    WHERE
        EXISTS (
            SELECT 1
            FROM reason r
            WHERE r.r_reason_sk = base.sr_reason_sk
              AND r.r_reason_desc = 'Damaged'
        )
    GROUP BY
        d_date,
        i_category
)
SELECT
    i_category AS category,
    ROUND(AVG(cat_sales + web_sales - store_return_loss - catalog_return_amount), 2) AS avg_daily_net_sales,
    SUM(total_inventory_on_hand) AS total_inventory,
    AVG(distinct_items_sold) AS avg_distinct_items_sold,
    COUNT(*) AS days_with_sales
FROM
    daily_category
GROUP BY
    i_category
HAVING
    AVG(cat_sales + web_sales - store_return_loss - catalog_return_amount) > 1000
ORDER BY
    avg_daily_net_sales DESC
LIMIT 100
