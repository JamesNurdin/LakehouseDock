WITH catalog_base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cp.cp_catalog_page_id,
        cp.cp_type,
        w.w_warehouse_name,
        r.r_reason_desc,
        td.t_hour,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_type = 'monthly'
      AND td.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
),
site_avg AS (
    SELECT
        ws.ws_web_site_sk,
        AVG(ws.ws_net_paid) AS avg_site_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk
)
SELECT
    cb.cp_catalog_page_id,
    ws_site.web_name,
    SUM(cb.cr_return_amount) AS total_catalog_return_amount,
    SUM(ws.ws_net_paid) AS total_web_sales_net_paid,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    CASE
        WHEN SUM(cb.cr_return_amount) > 10000 THEN 'High Return'
        WHEN SUM(cb.cr_return_amount) BETWEEN 5000 AND 10000 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category,
    (SELECT avg_site_net_paid FROM site_avg WHERE ws_site.web_site_sk = site_avg.ws_web_site_sk) AS avg_site_net_paid,
    DENSE_RANK() OVER (ORDER BY SUM(cb.cr_return_amount) DESC) AS catalog_return_rank,
    ROW_NUMBER() OVER (PARTITION BY ws_site.web_name ORDER BY SUM(cb.cr_return_amount) DESC) AS rn_by_site
FROM catalog_base cb
JOIN store_returns sr ON sr.sr_return_time_sk = cb.cr_returned_time_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN income_band ib_sr ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = cb.cr_returned_time_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
JOIN income_band ib_wr_refunded ON hd_wr_refunded.hd_income_band_sk = ib_wr_refunded.ib_income_band_sk
WHERE ws.ws_ext_discount_amt > 0
  AND sr.sr_return_quantity > 0
  AND wr.wr_return_quantity > 0
GROUP BY
    cb.cp_catalog_page_id,
    ws_site.web_name,
    ws_site.web_site_sk
ORDER BY
    catalog_return_rank ASC,
    total_catalog_return_amount DESC
LIMIT 100
