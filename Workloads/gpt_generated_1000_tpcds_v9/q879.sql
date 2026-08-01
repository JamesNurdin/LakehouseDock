WITH
    intersect_customers AS (
        SELECT ss.ss_customer_sk AS customer_sk
        FROM store_sales ss
        WHERE ss.ss_quantity > 5
        INTERSECT
        SELECT cr.cr_refunded_customer_sk AS customer_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 100
    ),
    except_customers AS (
        SELECT ss.ss_customer_sk AS customer_sk
        FROM store_sales ss
        WHERE ss.ss_quantity > 0
        EXCEPT
        SELECT cr.cr_refunded_customer_sk AS customer_sk
        FROM catalog_returns cr
    ),
    joined_all AS (
        SELECT
            ss.ss_sold_date_sk,
            d.d_date,
            d.d_year,
            d.d_month_seq,
            s.s_store_sk,
            s.s_store_name,
            s.s_state,
            i.i_item_sk,
            i.i_brand,
            i.i_category,
            i.i_item_desc,
            ca.ca_state AS ca_state,
            c.c_customer_sk,
            c.c_birth_year,
            hd.hd_demo_sk,
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            cc.cc_call_center_sk,
            cc.cc_name,
            cp.cp_catalog_page_sk,
            cp.cp_catalog_number,
            cp.cp_description,
            sm.sm_ship_mode_sk,
            sm.sm_type,
            w_cr.w_warehouse_sk,
            w_cr.w_city AS return_warehouse_city,
            w_inv.w_city AS inventory_warehouse_city,
            inv.inv_quantity_on_hand,
            ss.ss_quantity,
            ss.ss_sales_price,
            ss.ss_net_paid,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            wp.wp_web_page_sk,
            wp.wp_url,
            word
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN warehouse w_inv
            ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_item_sk = i.i_item_sk
            AND cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN warehouse w_cr
            ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
        LEFT JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN web_page wp
            ON wp.wp_customer_sk = c.c_customer_sk
        -- Expand item description into words
        CROSS JOIN LATERAL (SELECT split(i.i_item_desc, ' ') AS words) AS dw
        CROSS JOIN UNNEST(dw.words) AS t(word)
        WHERE s.s_state = 'CA'
          AND d.d_year BETWEEN 2001 AND 2002
          AND d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2003-01-01'
          AND i.i_brand = 'Brand#23'
          AND c.c_birth_year > 1970
          AND w_cr.w_city = 'Los Angeles'
          AND cc.cc_name LIKE '%Center%'
          AND c.c_customer_sk IN (SELECT customer_sk FROM intersect_customers)
          AND c.c_customer_sk NOT IN (SELECT customer_sk FROM except_customers)
    ),
    agg_by_store_month AS (
        SELECT
            s_store_sk,
            s_store_name,
            d_year,
            d_month_seq,
            SUM(ss_net_paid) AS total_net_paid,
            SUM(ss_quantity) AS total_quantity,
            SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
            COUNT(DISTINCT c_customer_sk) AS distinct_customers,
            SUM(inv_quantity_on_hand) AS total_inventory_on_hand
        FROM joined_all
        GROUP BY s_store_sk, s_store_name, d_year, d_month_seq
    ),
    final_result AS (
        SELECT
            a.s_store_name,
            a.d_year,
            a.d_month_seq,
            a.total_net_paid,
            a.total_quantity,
            a.total_return_amount,
            a.distinct_customers,
            a.total_inventory_on_hand,
            SUM(a.total_net_paid) OVER (PARTITION BY a.s_store_name ORDER BY a.d_year, a.d_month_seq) AS cum_net_paid,
            (SELECT AVG(ss_ext_discount_amt) FROM store_sales ss2 WHERE ss2.ss_store_sk = a.s_store_sk) AS avg_discount_amount,
            CASE WHEN EXISTS (
                SELECT 1
                FROM catalog_returns cr3
                JOIN store_sales ss3 ON cr3.cr_refunded_customer_sk = ss3.ss_customer_sk
                WHERE ss3.ss_store_sk = a.s_store_sk
                  AND cr3.cr_return_amount > 500
            ) THEN 1 ELSE 0 END AS has_high_return_customer
        FROM agg_by_store_month a
    )
SELECT *
FROM final_result
ORDER BY total_net_paid DESC
LIMIT 20
