WITH site_dates AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        ws.web_market_manager,
        d_open.d_date AS open_date,
        d_close.d_date AS close_date
    FROM web_site ws
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d_open.d_date IS NOT NULL
      AND d_close.d_date IS NOT NULL
)
SELECT
    sd.web_site_id,
    sd.web_name,
    r.r_reason_desc,
    d_ret.d_year,
    d_ret.d_month_seq,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    RANK() OVER (PARTITION BY sd.web_site_id ORDER BY SUM(cr.cr_net_loss) DESC) AS reason_rank
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN site_dates sd ON d_ret.d_date BETWEEN sd.open_date AND sd.close_date
WHERE cr.cr_warehouse_sk IN (7, 11, 12)
  AND d_ret.d_year = 2020
GROUP BY sd.web_site_id, sd.web_name, r.r_reason_desc, d_ret.d_year, d_ret.d_month_seq
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY sd.web_site_id, reason_rank
LIMIT 100
