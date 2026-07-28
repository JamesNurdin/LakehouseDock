WITH sr_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        SUM(sr.sr_return_quantity) AS sr_qty,
        SUM(sr.sr_return_amt_inc_tax) AS sr_amount
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 10
      AND sr.sr_return_amt_inc_tax > 200
      AND sr.sr_reversed_charge < 500
      AND sr.sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
      AND sr.sr_return_time_sk IN (SELECT t_time_sk FROM time_dim WHERE t_hour BETWEEN 9 AND 17)
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk, sr.sr_return_time_sk
),
wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        SUM(wr.wr_return_quantity) AS wr_qty,
        SUM(wr.wr_return_amt_inc_tax) AS wr_amount
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 5
      AND wr.wr_return_amt_inc_tax > 100
      AND wr.wr_fee > 0
      AND wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
      AND wr.wr_returned_time_sk IN (SELECT t_time_sk FROM time_dim WHERE t_hour BETWEEN 9 AND 17)
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk, wr.wr_returned_time_sk
),
combined_returns AS (
    SELECT
        sr_item_sk AS item_sk,
        sr_returned_date_sk AS returned_date_sk,
        sr_return_time_sk AS returned_time_sk,
        sr_qty,
        sr_amount,
        'store' AS src
    FROM sr_agg
    UNION ALL
    SELECT
        wr_item_sk,
        wr_returned_date_sk,
        wr_returned_time_sk,
        wr_qty,
        wr_amount,
        'web' AS src
    FROM wr_agg
),
cr_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        SUM(cr.cr_return_quantity) AS cr_qty,
        SUM(cr.cr_return_amt_inc_tax) AS cr_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 3
      AND cr.cr_return_amt_inc_tax > 50
      AND cr.cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
      AND cr.cr_call_center_sk IN (SELECT cc_call_center_sk FROM call_center WHERE cc_gmt_offset = -6.00)
      AND cr.cr_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM catalog_page WHERE cp_type = 'Catalog')
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk, cr.cr_returned_time_sk, cr.cr_call_center_sk, cr.cr_catalog_page_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_product_name,
    cp.cp_department,
    cc.cc_name,
    t.t_hour,
    SUM(COALESCE(c.cr_qty, 0)) AS catalog_return_qty,
    SUM(COALESCE(c.cr_amount, 0)) AS catalog_return_amount,
    SUM(COALESCE(r.sr_qty, 0)) AS store_return_qty,
    SUM(COALESCE(r.sr_amount, 0)) AS store_return_amount,
    COUNT(DISTINCT CASE WHEN r.src = 'store' THEN r.item_sk END) AS distinct_store_items,
    COUNT(DISTINCT CASE WHEN r.src = 'web' THEN r.item_sk END) AS distinct_web_items
FROM combined_returns r
LEFT JOIN cr_agg c
    ON r.item_sk = c.cr_item_sk
   AND r.returned_date_sk = c.cr_returned_date_sk
   AND r.returned_time_sk = c.cr_returned_time_sk
JOIN item i
    ON r.item_sk = i.i_item_sk
JOIN date_dim d
    ON r.returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON r.returned_time_sk = t.t_time_sk
LEFT JOIN call_center cc
    ON c.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON c.cr_catalog_page_sk = cp.cp_catalog_page_sk
GROUP BY d.d_year, d.d_month_seq, i.i_product_name, cp.cp_department, cc.cc_name, t.t_hour
HAVING SUM(COALESCE(c.cr_qty, 0)) > 0
   AND SUM(COALESCE(r.sr_qty, 0)) > 0
ORDER BY d.d_year DESC, catalog_return_amount DESC
LIMIT 100
