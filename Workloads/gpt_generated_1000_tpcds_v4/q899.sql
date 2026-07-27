WITH loss_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d1.d_year,
        cc.cc_name,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_loss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_loss,
        SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_loss
    FROM store_sales ss
    JOIN date_dim d1
        ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1
        ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r1
        ON sr.sr_reason_sk = r1.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d1.d_date_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN reason r2
        ON cr.cr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d1.d_date_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r3
        ON wr.wr_reason_sk = r3.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d1.d_date_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d1.d_year = 2001
      AND i.i_current_price > 50
      AND cc.cc_state = 'CA'
      AND (
            r1.r_reason_desc = 'Damaged'
         OR r2.r_reason_desc = 'Damaged'
         OR r3.r_reason_desc = 'Damaged'
          )
    GROUP BY i.i_item_id, i.i_product_name, d1.d_year, cc.cc_name
    HAVING SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 1000
)
SELECT
    la.i_item_id,
    la.i_product_name,
    la.d_year,
    la.cc_name,
    la.total_loss,
    ROW_NUMBER() OVER (PARTITION BY la.d_year ORDER BY la.total_loss DESC) AS rn,
    RANK() OVER (PARTITION BY la.d_year ORDER BY la.total_loss DESC) AS rnk
FROM loss_agg la
ORDER BY la.d_year, la.total_loss DESC
LIMIT 100
