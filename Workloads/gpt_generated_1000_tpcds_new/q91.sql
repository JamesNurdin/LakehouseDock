WITH sales_returns AS (
    SELECT
        w.w_warehouse_id,
        p.p_promo_id,
        r.r_reason_id,
        cd.cd_gender,
        ib.ib_income_band_sk,
        cs.cs_net_paid            AS catalog_net,
        ss.ss_net_paid            AS store_net,
        ws.ws_net_paid            AS web_net,
        cr.cr_net_loss            AS catalog_loss,
        sr.sr_net_loss            AS store_loss,
        wr.wr_net_loss            AS web_loss,
        sr.sr_fee                 AS sr_fee,
        wr.wr_return_amt          AS wr_return_amt,
        c.c_birth_year,
        p.p_channel_email,
        ib.ib_lower_bound,
        w.w_gmt_offset
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss
      ON ss.ss_ticket_number = cs.cs_order_number
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_sales ws
      ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN inventory i
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1970
      AND p.p_channel_email = 'N'
      AND sr.sr_fee > 10
      AND wr.wr_return_amt > 20
      AND ib.ib_lower_bound >= 30000
      AND w.w_gmt_offset BETWEEN -5 AND 0
),
agg AS (
    SELECT
        w_warehouse_id,
        p_promo_id,
        r_reason_id,
        cd_gender,
        ib_income_band_sk,
        SUM(catalog_net + store_net + web_net) AS total_net_paid,
        SUM(catalog_loss + store_loss + web_loss) AS total_net_loss
    FROM sales_returns
    GROUP BY GROUPING SETS (
        (w_warehouse_id, p_promo_id),
        (r_reason_id),
        (cd_gender, ib_income_band_sk)
    )
)
SELECT
    w_warehouse_id,
    p_promo_id,
    r_reason_id,
    cd_gender,
    ib_income_band_sk,
    total_net_paid,
    total_net_loss
FROM agg
WHERE total_net_paid > 1000
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
