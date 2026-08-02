WITH
    store_returns_agg AS (
        SELECT
            dr.d_date,
            dr.d_year,
            dr.d_month_seq,
            ca.ca_state,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
            SUM(sr.sr_net_loss) AS total_net_loss,
            COUNT(*) AS store_return_cnt
        FROM store_returns sr
        JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
        JOIN time_dim tr ON sr.sr_return_time_sk = tr.t_time_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE dr.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
          AND sr.sr_return_amt_inc_tax > 100.00
          AND ca.ca_state = 'CA'
        GROUP BY dr.d_date, dr.d_year, dr.d_month_seq, ca.ca_state
    ),
    web_returns_agg AS (
        SELECT
            dr.d_date,
            dr.d_year,
            dr.d_month_seq,
            ca.ca_state,
            SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
            SUM(wr.wr_net_loss) AS total_net_loss,
            COUNT(*) AS web_return_cnt
        FROM web_returns wr
        JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
        JOIN time_dim tr ON wr.wr_returned_time_sk = tr.t_time_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE dr.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
          AND wr.wr_return_amt_inc_tax > 100.00
          AND ca.ca_state = 'CA'
        GROUP BY dr.d_date, dr.d_year, dr.d_month_seq, ca.ca_state
    ),
    combined_returns AS (
        SELECT d_date, d_year, d_month_seq, ca_state,
               total_return_amt_inc_tax,
               total_net_loss,
               store_return_cnt,
               0 AS web_return_cnt
        FROM store_returns_agg
        UNION ALL
        SELECT d_date, d_year, d_month_seq, ca_state,
               total_return_amt_inc_tax,
               total_net_loss,
               0 AS store_return_cnt,
               web_return_cnt
        FROM web_returns_agg
    ),
    daily_aggregated AS (
        SELECT
            d_date,
            d_year,
            d_month_seq,
            ca_state,
            SUM(total_return_amt_inc_tax) AS sum_return_amt_inc_tax,
            SUM(total_net_loss) AS sum_net_loss,
            SUM(store_return_cnt) AS total_store_return_cnt,
            SUM(web_return_cnt) AS total_web_return_cnt
        FROM combined_returns
        GROUP BY d_date, d_year, d_month_seq, ca_state
    ),
    catalog_returns_agg AS (
        SELECT
            dr.d_date,
            dr.d_year,
            dr.d_month_seq,
            ca.ca_state,
            c.cc_name,
            cp.cp_department,
            sm.sm_type,
            w.w_warehouse_name,
            SUM(cr.cr_return_amt_inc_tax) AS catalog_total_return_amt_inc_tax,
            SUM(cr.cr_net_loss) AS catalog_total_net_loss,
            COUNT(*) AS catalog_return_cnt
        FROM catalog_returns cr
        JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
        JOIN time_dim tr ON cr.cr_returned_time_sk = tr.t_time_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN call_center c ON cr.cr_call_center_sk = c.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE dr.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
          AND cr.cr_return_amt_inc_tax > 200.00
          AND ca.ca_state = 'CA'
        GROUP BY dr.d_date, dr.d_year, dr.d_month_seq, ca.ca_state,
                 c.cc_name, cp.cp_department, sm.sm_type, w.w_warehouse_name
    ),
    inventory_agg AS (
        SELECT
            dr.d_date,
            dr.d_year,
            dr.d_month_seq,
            w.w_warehouse_name,
            SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
        FROM inventory inv
        JOIN date_dim dr ON inv.inv_date_sk = dr.d_date_sk
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE dr.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
          AND inv.inv_quantity_on_hand > 0
        GROUP BY dr.d_date, dr.d_year, dr.d_month_seq, w.w_warehouse_name
    ),
    final_agg AS (
        SELECT
            da.d_date,
            da.d_year,
            da.d_month_seq,
            da.ca_state,
            da.sum_return_amt_inc_tax,
            da.sum_net_loss,
            da.total_store_return_cnt,
            da.total_web_return_cnt,
            crAgg.catalog_total_return_amt_inc_tax,
            crAgg.catalog_total_net_loss,
            crAgg.catalog_return_cnt,
            invAgg.total_quantity_on_hand,
            ROW_NUMBER() OVER (ORDER BY da.d_date DESC) AS rn
        FROM daily_aggregated da
        LEFT JOIN catalog_returns_agg crAgg
            ON da.d_date = crAgg.d_date
           AND da.d_year = crAgg.d_year
           AND da.d_month_seq = crAgg.d_month_seq
           AND da.ca_state = crAgg.ca_state
        LEFT JOIN inventory_agg invAgg
            ON da.d_date = invAgg.d_date
           AND da.d_year = invAgg.d_year
           AND da.d_month_seq = invAgg.d_month_seq
        WHERE da.sum_return_amt_inc_tax > 500.00
    )
SELECT DISTINCT
    d_date,
    d_year,
    d_month_seq,
    ca_state,
    sum_return_amt_inc_tax,
    sum_net_loss,
    total_store_return_cnt,
    total_web_return_cnt,
    catalog_total_return_amt_inc_tax,
    catalog_total_net_loss,
    catalog_return_cnt,
    total_quantity_on_hand,
    rn
FROM final_agg
ORDER BY d_date DESC, rn
LIMIT 100
