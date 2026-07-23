WITH sales_agg AS (
    SELECT
        ws.web_site_id AS ws_id,
        ws.web_name AS web_name,
        i.i_category AS category,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        AVG(p.p_cost) AS avg_promo_cost,
        MAX(cc.cc_gmt_offset) AS max_gmt_offset,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS discount_active_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk AND p.p_start_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 50
      AND cc.cc_state = 'CA'
      AND cd.cd_gender = 'M'
      AND p.p_channel_catalog = 'N'
    GROUP BY ws.web_site_id, ws.web_name, i.i_category, d.d_year
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    a.ws_id,
    a.web_name,
    a.category,
    a.year,
    a.total_net_paid,
    a.total_quantity,
    a.distinct_tickets,
    a.avg_promo_cost,
    a.max_gmt_offset,
    a.discount_active_count,
    ROW_NUMBER() OVER (PARTITION BY a.ws_id ORDER BY a.total_net_paid DESC) AS sales_rank,
    (
        SELECT AVG(sa.total_net_paid)
        FROM sales_agg sa
        WHERE sa.category = a.category
    ) AS category_avg_net_paid,
    (
        SELECT array_agg(DISTINCT w.w_warehouse_id)
        FROM warehouse w
        JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN item i2 ON i2.i_item_sk = inv.inv_item_sk
        WHERE i2.i_category = a.category
    ) AS distinct_warehouses
FROM sales_agg a
ORDER BY a.total_net_paid DESC
LIMIT 100
