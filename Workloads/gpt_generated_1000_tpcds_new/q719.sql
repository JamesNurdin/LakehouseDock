WITH income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
)
SELECT
    ib.ib_income_band_sk AS income_band_sk,
    CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
    SUM(cr.cr_net_loss) AS total_loss,
    COUNT(*) AS return_cnt,
    MIN(t.t_time) AS earliest_time
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_brackets ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
WHERE regexp_like(i.i_item_desc, '(?i)BRAND')
  AND w.w_city LIKE 'A%'
  AND EXISTS (
      SELECT 1 FROM warehouse w2
      WHERE w2.w_warehouse_sk = cr.cr_warehouse_sk
        AND w2.w_county = 'Bronx County'
  )
GROUP BY ib.ib_income_band_sk,
         CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END

UNION DISTINCT

SELECT
    ib.ib_income_band_sk AS income_band_sk,
    CASE WHEN wr.wr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
    SUM(wr.wr_net_loss) AS total_loss,
    COUNT(*) AS return_cnt,
    MIN(t.t_time) AS earliest_time
FROM web_returns wr
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_brackets ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
  AND wp.wp_url LIKE '%shop%'
GROUP BY ib.ib_income_band_sk,
         CASE WHEN wr.wr_net_loss > 100 THEN 'High' ELSE 'Low' END
ORDER BY income_band_sk ASC, loss_category
