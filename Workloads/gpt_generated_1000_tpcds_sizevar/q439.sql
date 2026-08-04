WITH avg_return AS (
    SELECT AVG(cr_return_amount) AS avg_amt
    FROM catalog_returns
),
base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        cr.cr_call_center_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        dw.d_date,
        dw.d_year,
        i.i_item_id,
        i.i_brand,
        i.i_current_price,
        w.w_warehouse_name,
        w.w_state,
        cc.cc_name,
        cc.cc_employees,
        r.r_reason_desc,
        p.p_promo_name,
        p.p_discount_active,
        inv.inv_quantity_on_hand,
        t.t_hour,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        ws.web_site_id
    FROM catalog_returns cr
    JOIN date_dim dw ON cr.cr_returned_date_sk = dw.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk <= cr.cr_returned_date_sk
        AND p.p_end_date_sk >= cr.cr_returned_date_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = cr.cr_returned_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = dw.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk <= cr.cr_returned_date_sk
        AND (ws.web_close_date_sk IS NULL OR ws.web_close_date_sk >= cr.cr_returned_date_sk)
    WHERE dw.d_year = 2001
      AND w.w_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cc.cc_employees > 50
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
      AND inv.inv_quantity_on_hand < 100
      AND r.r_reason_desc LIKE '%damaged%'
      AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
)
SELECT DISTINCT
    b.i_item_id,
    b.w_warehouse_name,
    b.d_date,
    b.cc_name,
    b.r_reason_desc,
    b.p_promo_name,
    b.cr_return_amount,
    b.cr_net_loss,
    b.inv_quantity_on_hand,
    b.wr_return_quantity,
    b.wr_return_amt,
    (
        SELECT SUM(wr2.wr_return_quantity)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = b.cr_item_sk
          AND wr2.wr_returned_date_sk = b.cr_returned_date_sk
    ) AS total_web_return_qty_same_day,
    RANK() OVER (PARTITION BY b.d_year ORDER BY b.cr_return_amount DESC) AS return_amount_rank
FROM base b
ORDER BY return_amount_rank
LIMIT 100
