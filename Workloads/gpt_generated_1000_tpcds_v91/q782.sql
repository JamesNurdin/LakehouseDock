WITH catalog_ret_raw AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_refunded_customer_sk AS cust_sk,
        cr.cr_ship_mode_sk AS ship_mode_sk,
        cr.cr_warehouse_sk AS warehouse_sk,
        cr.cr_catalog_page_sk AS catalog_page_sk,
        cr.cr_reason_sk AS reason_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
),
web_ret_raw AS (
    SELECT
        wr.wr_returned_date_sk AS returned_date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_refunded_customer_sk AS cust_sk,
        CAST(NULL AS integer) AS ship_mode_sk,
        CAST(NULL AS integer) AS warehouse_sk,
        CAST(NULL AS integer) AS catalog_page_sk,
        wr.wr_reason_sk AS reason_sk,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity AS return_quantity
    FROM web_returns wr
),
combined_returns AS (
    SELECT * FROM catalog_ret_raw
    UNION ALL
    SELECT * FROM web_ret_raw
),
inventory_warehouse AS (
    SELECT
        inv.inv_warehouse_sk,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state
    FROM inventory inv
    RIGHT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
cp_full AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_end_date_sk,
        cp.cp_department,
        cp.cp_description,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq
    FROM catalog_page cp
    FULL OUTER JOIN date_dim d
        ON cp.cp_end_date_sk = d.d_date_sk
),
agg_returns AS (
    SELECT
        i.i_item_id,
        i.i_item_sk,
        d.d_year,
        SUM(cr.return_amount) AS total_return_amount,
        SUM(cr.return_quantity) AS total_return_qty,
        COUNT(*) AS total_return_cnt,
        AVG(cr.return_amount) AS avg_return_amount,
        MAX(cr.return_amount) AS max_return_amount,
        MAX(w.w_warehouse_name) AS warehouse_name,
        MAX(w.w_state) AS warehouse_state,
        MAX(sm.sm_ship_mode_id) AS ship_mode_id,
        MAX(cp.cp_department) AS catalog_department,
        MAX(ca.ca_state) AS customer_state,
        MAX(hd.hd_vehicle_count) AS vehicle_count,
        MAX(ib.ib_lower_bound) AS income_lower_bound,
        MAX(w.w_warehouse_sk) AS warehouse_sk,
        MAX(cp.cp_catalog_page_sk) AS catalog_page_sk
    FROM combined_returns cr
    JOIN date_dim d
        ON cr.returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.item_sk = i.i_item_sk
    JOIN reason r
        ON cr.reason_sk = r.r_reason_sk
    LEFT JOIN ship_mode sm
        ON cr.ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_page cp
        ON cr.catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cr.cust_sk = c.c_customer_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_size = 'small'
      AND r.r_reason_desc LIKE '%size%'
      AND sm.sm_code = 'AIR'
      AND w.w_state = 'CA'
    GROUP BY i.i_item_id, i.i_item_sk, d.d_year
)
SELECT
    ar.i_item_id,
    ar.d_year,
    ar.total_return_amount,
    ar.total_return_qty,
    ar.total_return_cnt,
    ar.avg_return_amount,
    ar.max_return_amount,
    ar.warehouse_name,
    ar.warehouse_state,
    ar.ship_mode_id,
    ar.catalog_department,
    ar.customer_state,
    ar.vehicle_count,
    ar.income_lower_bound,
    -- correlated subquery: total return amount for the same year across all items
    (SELECT SUM(ar2.total_return_amount)
     FROM agg_returns ar2
     WHERE ar2.d_year = ar.d_year) AS year_total_return_amount,
    -- window function: rank items by total return amount within each year
    RANK() OVER (PARTITION BY ar.d_year ORDER BY ar.total_return_amount DESC) AS rank_by_amount,
    -- correlated subquery: total inventory quantity for the warehouse of this row
    (SELECT SUM(iw.inv_quantity_on_hand)
     FROM inventory_warehouse iw
     WHERE iw.w_warehouse_sk = ar.warehouse_sk) AS total_inventory_quantity,
    -- correlated subquery: description from full outer join of catalog_page and date_dim
    (SELECT MAX(cp_f.cp_description)
     FROM cp_full cp_f
     WHERE cp_f.cp_catalog_page_sk = ar.catalog_page_sk) AS full_cp_description
FROM agg_returns ar
ORDER BY ar.total_return_amount DESC
LIMIT 100
