WITH joined_all AS (
    SELECT
        d_ret.d_year AS d_year,
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        sm.sm_type AS ship_mode_type,
        r.r_reason_desc AS reason_desc,
        cp.cp_department AS catalog_department,
        wp.wp_type AS web_page_type,
        ws.web_name AS web_site_name,
        cr.cr_order_number AS order_number,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_amount AS return_amount,
        inv.inv_quantity_on_hand AS quantity_on_hand,
        ss.ss_quantity AS sold_quantity,
        ss.ss_net_paid AS net_paid
    FROM catalog_returns cr
    -- link return to date and time dimensions
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    -- catalog page and reason information
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    -- shipping mode used for the return
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    -- associate the return with the corresponding store sale (same date & time)
    JOIN store_sales ss ON cr.cr_returned_date_sk = ss.ss_sold_date_sk
                        AND cr.cr_returned_time_sk = ss.ss_sold_time_sk
    JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    -- store that performed the sale
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    -- inventory snapshot for the return date
    JOIN inventory inv ON inv.inv_date_sk = d_ret.d_date_sk
                         AND inv.inv_item_sk = cr.cr_item_sk
    -- web page that might have shown the catalog page (joined via creation date)
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    -- web site that was active on the return date (joined via open date)
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    -- filter predicates (at least three)
    WHERE d_ret.d_year = 2001
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
),
aggregated AS (
    SELECT
        d_year,
        s_store_name,
        catalog_department,
        SUM(net_loss) AS total_net_loss,
        COUNT(DISTINCT order_number) AS distinct_orders,
        SUM(return_amount) AS total_return_amount,
        SUM(quantity_on_hand) AS total_quantity_on_hand,
        SUM(sold_quantity) AS total_sold_quantity,
        SUM(net_paid) AS total_net_paid
    FROM joined_all
    GROUP BY d_year, s_store_name, catalog_department
    HAVING SUM(net_loss) > 0
)
SELECT
    d_year,
    s_store_name,
    catalog_department,
    total_net_loss,
    distinct_orders,
    total_return_amount,
    total_quantity_on_hand,
    total_sold_quantity,
    total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_net_loss DESC) AS rn
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
