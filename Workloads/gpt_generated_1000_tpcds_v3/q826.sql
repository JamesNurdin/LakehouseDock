WITH store_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_reason_sk,
        SUM(sr_net_loss) AS store_net_loss,
        SUM(sr_return_quantity) AS store_return_qty,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    WHERE sr_return_quantity >= 2
      AND sr_return_amt > 0
    GROUP BY sr_returned_date_sk, sr_reason_sk
)
SELECT
    d_sr.d_year,
    r_sr.r_reason_desc,
    SUM(sa.store_net_loss) AS total_store_net_loss,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(sa.store_return_qty) AS total_store_return_qty,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
    CASE
        WHEN SUM(sa.store_net_loss + cr.cr_net_loss + wr.wr_net_loss) > 10000 THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    (
        SELECT MAX(ws_sub.web_tax_percentage)
        FROM web_site ws_sub
        WHERE ws_sub.web_country = 'United States'
    ) AS max_us_tax_pct
FROM store_agg sa
JOIN date_dim d_sr ON sa.sr_returned_date_sk = d_sr.d_date_sk
JOIN reason r_sr ON sa.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sr.d_date_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sr.d_date_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sr.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_sr.d_year = 2001
  AND d_sr.d_month_seq = 12
  AND cr.cr_fee > 70.00
  AND wr.wr_return_amt < 300.00
  AND ws.web_gmt_offset = -5.00
GROUP BY d_sr.d_year, r_sr.r_reason_desc
ORDER BY total_store_net_loss DESC
LIMIT 100
