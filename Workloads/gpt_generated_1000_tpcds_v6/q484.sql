WITH reason_agg AS (
    SELECT r_reason_sk,
           COUNT(*)               AS catalog_return_cnt,
           SUM(cr.cr_net_loss)    AS catalog_net_loss
    FROM   catalog_returns cr
           JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_sk
)
SELECT
    r.r_reason_desc,
    sm.sm_type,
    w.w_warehouse_name,
    s.s_store_name,
    ws.web_name,
    COUNT(*)                                 AS total_returns,
    SUM(cr.cr_net_loss)                      AS total_catalog_loss,
    SUM(wr.wr_net_loss)                      AS total_web_loss,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_loss
FROM   catalog_returns cr
       -- reason for the return
       JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
       -- shipping mode and warehouse details
       JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
       JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
       -- returned date (used also for several other joins)
       JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
       -- customer dimensions – refunded and returning as separate aliases
       JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
       JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
       -- demographics for both sides
       JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
       JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
       -- address for both sides
       JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
       JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
       -- store that closed on the return date
       JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
       -- web return that happened on the same date and for the same refunded customer
       JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
                           AND wr.wr_refunded_customer_sk = c_ref.c_customer_sk
       -- web page linked to the web return
       JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
       -- web site (using its open date as a second date dimension)
       JOIN web_site ws ON ws.web_open_date_sk = ws.web_open_date_sk  -- self‑join placeholder to create alias
       JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
WHERE  d_ret.d_year = 2001
  AND r.r_reason_desc LIKE '%damaged%'
  AND EXISTS (
        SELECT 1
        FROM   reason_agg ra
        WHERE  ra.r_reason_sk = r.r_reason_sk
          AND  ra.catalog_return_cnt > 10
    )
GROUP BY
    r.r_reason_desc,
    sm.sm_type,
    w.w_warehouse_name,
    s.s_store_name,
    ws.web_name
ORDER BY total_loss DESC
LIMIT 100
