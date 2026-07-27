WITH sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        ss.ss_promo_sk,
        ss.ss_cdemo_sk
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i_sales ON ss.ss_item_sk = i_sales.i_item_sk
    JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    JOIN promotion p_sales ON ss.ss_promo_sk = p_sales.p_promo_sk
),
returns_agg AS (
    SELECT
        sr.sr_ticket_number,
        SUM(sr.sr_return_amt) AS return_amt
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    GROUP BY sr.sr_ticket_number
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        inv.inv_warehouse_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY inv.inv_item_sk, inv.inv_date_sk, inv.inv_warehouse_sk
),
promo_agg AS (
    SELECT
        p.p_item_sk,
        COUNT(DISTINCT p.p_promo_id) AS promo_cnt
    FROM promotion p
    JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
    GROUP BY p.p_item_sk
),
catalog_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk,
        COUNT(*) AS catalog_page_cnt
    FROM catalog_page cp
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    GROUP BY cp.cp_catalog_page_id, cp.cp_start_date_sk, cp.cp_end_date_sk
),
web_agg AS (
    SELECT
        wp.wp_web_page_id,
        AVG(wp.wp_link_count) AS avg_link_cnt
    FROM web_page wp
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    GROUP BY wp.wp_web_page_id
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COALESCE(SUM(r.return_amt), 0) AS total_returns,
    AVG(inv.avg_qty_on_hand) AS avg_inventory,
    COALESCE(promo.promo_cnt, 0) AS promo_count,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_pages,
    (SELECT AVG(avg_link_cnt) FROM web_agg) AS avg_web_links
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN returns_agg r ON ss.ss_ticket_number = r.sr_ticket_number
LEFT JOIN inventory_agg inv ON ss.ss_item_sk = inv.inv_item_sk
LEFT JOIN promo_agg promo ON ss.ss_item_sk = promo.p_item_sk
LEFT JOIN catalog_agg cp ON d_sales.d_date_sk = cp.cp_start_date_sk
GROUP BY i.i_item_id, i.i_product_name, d_sales.d_year, d_sales.d_month_seq, promo.promo_cnt
ORDER BY total_sales DESC
LIMIT 100
