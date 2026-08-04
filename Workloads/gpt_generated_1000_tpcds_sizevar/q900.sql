WITH inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_date_sk
)
SELECT
    d.d_date,
    cc.cc_name,
    cd.cd_credit_rating,
    sm.sm_type,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    inv_agg.total_qty,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
FROM catalog_returns cr
JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer c               ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc           ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm             ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr          ON wr.wr_returned_date_sk = d.d_date_sk
                               AND wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN promotion p              ON p.p_start_date_sk = d.d_date_sk
JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inv_agg                  ON inv_agg.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cc.cc_country = 'United States'
  AND cd.cd_credit_rating = 'High Risk'
  AND ib.ib_lower_bound >= 50000
  AND sm.sm_type = 'AIR'
  AND cc.cc_gmt_offset > (
        SELECT MIN(cc2.cc_gmt_offset)
        FROM call_center cc2
        WHERE cc2.cc_country = 'United States'
      )
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_start_date_sk = d.d_date_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY
    d.d_date,
    cc.cc_name,
    cd.cd_credit_rating,
    sm.sm_type,
    inv_agg.total_qty
ORDER BY total_catalog_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
