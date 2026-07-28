WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    d_ret.d_year,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    cd_ref.cd_gender      AS refunded_gender,
    cd_ret.cd_gender      AS returning_gender,
    i.inv_quantity_on_hand,
    cp_stats.max_page_num,
    SUM(base.cr_return_amount) AS total_return_amount,
    SUM(base.cr_return_quantity) AS total_return_qty,
    SUM(base.cr_net_loss) AS total_net_loss
FROM base
-- join to the date of the return
JOIN date_dim d_ret
    ON base.cr_returned_date_sk = d_ret.d_date_sk
-- join to the call center that handled the return
JOIN call_center cc
    ON base.cr_call_center_sk = cc.cc_call_center_sk
-- join to the catalog page of the returned item
JOIN catalog_page cp
    ON base.cr_catalog_page_sk = cp.cp_catalog_page_sk
-- join to the shipping mode used
JOIN ship_mode sm
    ON base.cr_ship_mode_sk = sm.sm_ship_mode_sk
-- join to the refunded customer demographic (aliased)
JOIN customer_demographics cd_ref
    ON base.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
-- join to the returning customer demographic (second alias)
JOIN customer_demographics cd_ret
    ON base.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
-- join a second date dimension for the call‑center closed date
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
-- join web returns that happened on the same return date
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
-- join inventory for the same item
JOIN inventory i
    ON i.inv_item_sk = base.cr_item_sk
-- join a third date dimension for the inventory date
JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
-- lateral sub‑query to fetch the max catalog page number for the department
CROSS JOIN LATERAL (
    SELECT MAX(cp2.cp_catalog_page_number) AS max_page_num
    FROM catalog_page cp2
    WHERE cp2.cp_department = cp.cp_department
) AS cp_stats
WHERE d_ret.d_fy_quarter_seq = 13
  AND d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
GROUP BY
    d_ret.d_year,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    cd_ref.cd_gender,
    cd_ret.cd_gender,
    i.inv_quantity_on_hand,
    cp_stats.max_page_num
ORDER BY total_return_amount DESC
LIMIT 100
