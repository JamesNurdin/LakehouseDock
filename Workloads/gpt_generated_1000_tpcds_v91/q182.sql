WITH sales_returns AS (
    SELECT
        it.i_category,
        r.r_reason_desc,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COALESCE(COUNT(DISTINCT cr.cr_order_number), 0) AS return_transactions,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory,
        MIN(d_sales.d_date) AS sales_start_date,
        MAX(d_return.d_date) AS return_end_date,
        MIN(d_small.d_date_sk) AS sample_date_key,
        SUM(t.rep_factor) AS rep_factor_sum,
        MAX(wp_l.wp_max_ad_count) AS max_page_ad_count,
        MAX(cc.cc_name) AS call_center_name
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN item it ON ss.ss_item_sk = it.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = it.i_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    LEFT JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = it.i_item_sk
        AND inv.inv_date_sk = d_sales.d_date_sk
    LEFT JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    CROSS JOIN LATERAL (
        SELECT wp.wp_type, wp.wp_max_ad_count
        FROM web_page wp
        WHERE wp.wp_creation_date_sk = d_sales.d_date_sk
        ORDER BY wp.wp_max_ad_count DESC
        LIMIT 1
    ) AS wp_l
    CROSS JOIN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001 LIMIT 5) AS d_small
    CROSS JOIN UNNEST(ARRAY[1,2,3]) AS t(rep_factor)
    WHERE d_sales.d_year = 2001
      AND it.i_current_price > 50
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND r.r_reason_desc LIKE '%damaged%'
      AND inv.inv_quantity_on_hand > 0
      AND t1.t_hour BETWEEN 9 AND 17
    GROUP BY ROLLUP (it.i_category, r.r_reason_desc)
)
SELECT
    sr.i_category,
    sr.r_reason_desc,
    sr.total_net_paid,
    sr.total_sales_price,
    sr.total_return_amount,
    sr.sales_transactions,
    sr.return_transactions,
    sr.total_inventory,
    sr.sales_start_date,
    sr.return_end_date,
    sr.sample_date_key,
    sr.rep_factor_sum,
    sr.max_page_ad_count,
    sr.call_center_name,
    (sr.total_net_paid / (SELECT SUM(ss2.ss_net_paid) FROM store_sales ss2)) AS net_paid_share
FROM sales_returns sr
WHERE sr.total_net_paid > 0
ORDER BY sr.total_net_paid DESC
LIMIT 100
