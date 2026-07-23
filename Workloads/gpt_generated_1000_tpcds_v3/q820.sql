WITH cr_summary AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20.00
    GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk, w.w_warehouse_name
)
SELECT
    d.d_year,
    i.i_category,
    cr_summary.w_warehouse_name,
    SUM(sr.sr_return_amt) AS store_return_total,
    AVG(sr.sr_return_amt) AS store_return_avg,
    SUM(wr.wr_return_amt) AS web_return_total,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_txns,
    cr_summary.total_catalog_return_amount,
    cr_summary.catalog_return_cnt,
    (
        SELECT AVG(cd2.cd_purchase_estimate)
        FROM customer_demographics cd2
        WHERE cd2.cd_gender = cd.cd_gender
    ) AS avg_purchase_estimate_by_gender
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
JOIN cr_summary ON cr_summary.cr_returned_date_sk = d.d_date_sk AND cr_summary.cr_item_sk = i.i_item_sk
WHERE d.d_month_seq BETWEEN 1210 AND 1220
  AND cd.cd_purchase_estimate > (
        SELECT AVG(cd3.cd_purchase_estimate) FROM customer_demographics cd3
    )
  AND hd.hd_vehicle_count >= 2
  AND s.s_state = 'CA'
GROUP BY d.d_year, i.i_category, cr_summary.w_warehouse_name, cr_summary.total_catalog_return_amount, cr_summary.catalog_return_cnt, cd.cd_gender
ORDER BY d.d_year DESC, i.i_category, cr_summary.w_warehouse_name
LIMIT 100
