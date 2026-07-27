WITH filtered_store_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_net_loss,
        sr.sr_ticket_number,
        sr.sr_cdemo_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_amt_inc_tax > 100
)
SELECT
    s.s_store_name,
    d_ret.d_year,
    COUNT(DISTINCT f.sr_ticket_number)                         AS store_return_cnt,
    SUM(f.sr_net_loss)                                         AS total_store_net_loss,
    AVG(f.sr_fee)                                              AS avg_store_fee,
    SUM(cr.cr_net_loss)                                        AS total_catalog_net_loss,
    SUM(wr.wr_net_loss)                                        AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_order_number)                         AS catalog_return_cnt,
    COUNT(DISTINCT wr.wr_order_number)                         AS web_return_cnt
FROM filtered_store_returns f
JOIN store s ON s.s_store_sk = f.sr_store_sk
JOIN date_dim d_ret ON f.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd ON f.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
   AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
   AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE s.s_country = 'United States'
  AND s.s_manager = 'Wayne Coleman'
  AND s.s_suite_number = 'Suite 190'
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
          AND p.p_start_date_sk = d_ret.d_date_sk
          AND p.p_end_date_sk >= d_ret.d_date_sk
      )
GROUP BY s.s_store_name, d_ret.d_year
ORDER BY total_store_net_loss DESC
LIMIT 100
