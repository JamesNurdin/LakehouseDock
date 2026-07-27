WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_catalog_page_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        r.r_reason_desc,
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        ib.ib_upper_bound
    FROM catalog_returns cr
    INNER JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE r.r_reason_desc LIKE '%size%'
      AND cp.cp_catalog_number BETWEEN 10 AND 20
      AND ib.ib_upper_bound >= 50000
), ranked_returns AS (
    SELECT
        *, 
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY cr_net_loss DESC) AS loss_rank
    FROM filtered_returns
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    cp_catalog_page_id,
    r_reason_desc,
    cr_return_amount,
    cr_net_loss,
    ib_upper_bound,
    loss_rank
FROM ranked_returns
ORDER BY loss_rank, cr_net_loss DESC
LIMIT 100
