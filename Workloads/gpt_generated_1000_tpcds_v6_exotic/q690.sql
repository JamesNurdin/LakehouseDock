WITH base AS (
    -- Combine store returns and catalog returns
    SELECT
        sr.sr_item_sk                     AS item_sk,
        sr.sr_return_time_sk               AS time_sk,
        sr.sr_return_quantity              AS return_qty,
        sr.sr_net_loss                     AS net_loss,
        sr.sr_store_sk                     AS store_sk,
        sr.sr_reason_sk                    AS reason_sk,
        CAST(NULL AS integer)              AS call_center_sk,
        sr.sr_hdemo_sk                     AS hd_demo_sk,
        sr.sr_cdemo_sk                     AS cd_demo_sk,
        sr.sr_customer_sk                  AS customer_sk
    FROM store_returns sr
    UNION ALL
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        CAST(NULL AS integer),                  -- no store for catalog returns
        cr.cr_reason_sk,
        cr.cr_call_center_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_customer_sk
    FROM catalog_returns cr
)
SELECT
    i.i_item_id,
    i.i_category,
    i.i_current_price,
    s.s_store_name,
    cc.cc_name,
    r.r_reason_desc,
    td.t_hour,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    inv.inv_quantity_on_hand,
    ws.ws_net_paid,
    base.return_qty,
    base.net_loss,
    RANK() OVER (PARTITION BY i.i_category ORDER BY base.net_loss DESC) AS loss_rank,
    CASE WHEN base.net_loss > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS loss_severity
FROM base
INNER JOIN item i               ON base.item_sk = i.i_item_sk
INNER JOIN time_dim td          ON base.time_sk = td.t_time_sk
LEFT  JOIN store s               ON base.store_sk = s.s_store_sk               -- outer join, many rows have no store
LEFT  JOIN call_center cc       ON base.call_center_sk = cc.cc_call_center_sk -- outer join, many rows have no call center
INNER JOIN reason r             ON base.reason_sk = r.r_reason_sk
INNER JOIN customer c           ON base.customer_sk = c.c_customer_sk
INNER JOIN customer_demographics cd ON base.cd_demo_sk = cd.cd_demo_sk
INNER JOIN household_demographics hd ON base.hd_demo_sk = hd.hd_demo_sk
INNER JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN inventory inv        ON i.i_item_sk = inv.inv_item_sk
INNER JOIN web_sales ws         ON i.i_item_sk = ws.ws_item_sk
INNER JOIN web_returns wr       ON ws.ws_item_sk = wr.wr_item_sk
                                 AND ws.ws_order_number = wr.wr_order_number
LEFT  JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE i.i_current_price > 200
  AND td.t_hour BETWEEN 8 AND 20
  AND ib.ib_lower_bound >= 50000
  AND r.r_reason_id LIKE 'AAAA%'
ORDER BY loss_rank ASC, base.net_loss DESC
LIMIT 100
