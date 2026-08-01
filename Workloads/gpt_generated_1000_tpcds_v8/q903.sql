WITH
    -- Join all tables with the allowed join keys and apply several filters
    joined_all AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amt_inc_tax,
            cr.cr_return_quantity,
            d.d_date,
            d.d_year,
            cp.cp_department,
            cp.cp_catalog_number,
            hd_ref.hd_buy_potential,
            ca_ref.ca_state,
            s.s_store_name,
            i.inv_quantity_on_hand,
            t.t_hour,
            ib.ib_upper_bound
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        JOIN inventory i ON i.inv_date_sk = d.d_date_sk
        WHERE d.d_year = 2000                                         -- predicate 1
          AND cp.cp_department = 'Electronics'                        -- predicate 2
          AND ca_ref.ca_state = 'CA'                                   -- predicate 3
          AND hd_ref.hd_buy_potential = '1001-5000'                    -- predicate 4
          AND i.inv_quantity_on_hand > 0                               -- predicate 5
          AND ib.ib_upper_bound < 50000                                 -- predicate 6
    ),
    -- Aggregate per day / department / year
    aggregated AS (
        SELECT
            ja.d_date,
            ja.d_year,
            ja.cp_department,
            SUM(ja.cr_return_amt_inc_tax) AS sum_return_amount,
            AVG(ja.inv_quantity_on_hand) AS avg_inventory_on_hand
        FROM joined_all ja
        GROUP BY ja.d_date, ja.d_year, ja.cp_department
        HAVING SUM(ja.cr_return_amt_inc_tax) > 1000
    ),
    -- Add a window function
    final_window AS (
        SELECT
            a.*,
            row_number() OVER (PARTITION BY a.d_year ORDER BY a.sum_return_amount DESC) AS rn_year
        FROM aggregated a
    ),
    -- UNION of catalog and web returns totals (deduped by UNION)
    union_returns AS (
        SELECT d_date, total_return
        FROM (
            SELECT d.d_date, SUM(cr.cr_return_amt_inc_tax) AS total_return
            FROM catalog_returns cr
            JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
            GROUP BY d.d_date
            UNION
            SELECT d.d_date, SUM(wr.wr_return_amt_inc_tax) AS total_return
            FROM web_returns wr
            JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
            GROUP BY d.d_date
        ) u
    ),
    -- Orders that appear in catalog returns but not in web returns
    except_orders AS (
        SELECT cr_order_number FROM catalog_returns
        EXCEPT
        SELECT wr_order_number FROM web_returns
    ),
    -- Addresses that appear in both refund streams
    intersect_addresses AS (
        SELECT cr.cr_refunded_addr_sk AS addr_sk FROM catalog_returns cr
        INTERSECT
        SELECT wr.wr_refunded_addr_sk FROM web_returns wr
    ),
    -- Helper CTEs to prepare a FULL OUTER JOIN between catalog pages and web pages via their start/creation dates
    cp_dates AS (
        SELECT cp.cp_catalog_page_id, d.d_date
        FROM catalog_page cp
        JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
        WHERE cp.cp_type = 'Promotion'
    ),
    wp_dates AS (
        SELECT wp.wp_web_page_id, d.d_date
        FROM web_page wp
        JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
        WHERE wp.wp_type = 'Landing'
    ),
    full_outer_join_cp_wp AS (
        SELECT
            cp.cp_catalog_page_id,
            wp.wp_web_page_id,
            COALESCE(cp.d_date, wp.d_date) AS join_date
        FROM cp_dates cp
        FULL OUTER JOIN wp_dates wp ON cp.d_date = wp.d_date
    )
SELECT
    fw.d_date,
    fw.cp_department,
    fw.sum_return_amount,
    fw.avg_inventory_on_hand,
    fw.rn_year,
    ur.total_return,
    eo.cr_order_number AS excluded_order,
    ia.addr_sk AS intersect_addr,
    foj.cp_catalog_page_id,
    foj.wp_web_page_id,
    foj.join_date
FROM final_window fw
LEFT JOIN union_returns ur ON fw.d_date = ur.d_date
LEFT JOIN (SELECT MIN(cr_order_number) AS cr_order_number FROM except_orders) eo ON TRUE
LEFT JOIN (SELECT MIN(addr_sk) AS addr_sk FROM intersect_addresses) ia ON TRUE
LEFT JOIN full_outer_join_cp_wp foj ON fw.d_date = foj.join_date
ORDER BY fw.sum_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
