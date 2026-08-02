WITH cr_base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_catalog_page_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_store_credit,
        cr.cr_net_loss,
        ARRAY[cr.cr_return_amount, cr.cr_return_tax] AS return_amounts,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_description,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk,
        reason.r_reason_desc,
        d.d_year,
        w.w_warehouse_id,
        w.w_city
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason
        ON cr.cr_reason_sk = reason.r_reason_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_store_credit > 50
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_item_sk = cr.cr_item_sk
            AND inv.inv_warehouse_sk = cr.cr_warehouse_sk
            AND inv.inv_date_sk = cr.cr_returned_date_sk
      )
)
SELECT
    crb.w_warehouse_id AS w_id,
    crb.d_year AS year,
    crb.cp_department AS department,
    MIN(d_start.d_year) AS start_year,
    MAX(d_end.d_year) AS end_year,
    SUM(crb.cr_return_quantity) AS total_return_qty,
    SUM(crb.cr_return_amount) AS total_return_amount,
    SUM(crb.cr_store_credit) AS total_store_credit,
    SUM(crb.cr_net_loss) AS total_net_loss,
    SUM(u.return_amount_item) AS total_amounts_from_array,
    SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
    COUNT(*) AS return_rows,
    GROUPING(crb.w_warehouse_id) AS grp_w,
    GROUPING(crb.d_year) AS grp_year,
    GROUPING(crb.cp_department) AS grp_dept
FROM cr_base crb
-- join to capture web return information via a shared date dimension
JOIN date_dim d_web
    ON crb.cr_returned_date_sk = d_web.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_web.d_date_sk
JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
-- join to start and end dates of the catalog page
JOIN date_dim d_start
    ON crb.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON crb.cp_end_date_sk = d_end.d_date_sk
-- join to inventory and its warehouse via a separate date dimension
JOIN date_dim d_inv
    ON crb.cr_returned_date_sk = d_inv.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w_inv
    ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
CROSS JOIN UNNEST(crb.return_amounts) AS u(return_amount_item)
GROUP BY ROLLUP (crb.w_warehouse_id, crb.d_year, crb.cp_department)
ORDER BY crb.w_warehouse_id, crb.d_year, crb.cp_department
