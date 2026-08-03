/*
  Goal: Identify catalog return transactions that overlap with store, web sales and web return activity for the same items, enriched with item, demographic and reason information, and compare two overlapping date‑range slices.
*/
WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        i.i_category,
        i.i_current_price,
        cp.cp_department,
        r.r_reason_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_net_paid_inc_tax,
        sr.sr_return_amt,
        wr.wr_return_amt,
        ROW_NUMBER() OVER (ORDER BY cr.cr_returned_date_sk) AS row_num
    FROM catalog_returns cr
        TABLESAMPLE BERNOULLI (10)    -- sample 10 % of catalog_returns rows
        JOIN item i               ON cr.cr_item_sk               = i.i_item_sk
        JOIN catalog_page cp      ON cr.cr_catalog_page_sk       = cp.cp_catalog_page_sk
        JOIN reason r             ON cr.cr_reason_sk              = r.r_reason_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib       ON hd.hd_income_band_sk         = ib.ib_income_band_sk
        JOIN store_returns sr     ON sr.sr_item_sk                = cr.cr_item_sk
        JOIN web_sales ws         ON ws.ws_item_sk                = cr.cr_item_sk
        JOIN web_returns wr       ON wr.wr_item_sk                = cr.cr_item_sk
        JOIN web_page wp          ON ws.ws_web_page_sk            = wp.wp_web_page_sk
        JOIN customer_address ca  ON cr.cr_refunded_addr_sk       = ca.ca_address_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk  = cd.cd_demo_sk
)
SELECT
    q1.row_num,
    q1.cr_returned_date_sk,
    q1.i_category,
    q1.cp_department,
    q1.r_reason_desc,
    q1.ib_lower_bound,
    q1.ws_net_paid_inc_tax,
    q1.sr_return_amt,
    q1.wr_return_amt
FROM (
    SELECT
        row_num,
        cr_returned_date_sk,
        i_category,
        cp_department,
        r_reason_desc,
        ib_lower_bound,
        ws_net_paid_inc_tax,
        sr_return_amt,
        wr_return_amt
    FROM joined
    WHERE cr_returned_date_sk BETWEEN 2451000 AND 2452000
      AND i_current_price > 50
      AND ib_upper_bound < 50000
) q1
INTERSECT
SELECT
    q2.row_num,
    q2.cr_returned_date_sk,
    q2.i_category,
    q2.cp_department,
    q2.r_reason_desc,
    q2.ib_lower_bound,
    q2.ws_net_paid_inc_tax,
    q2.sr_return_amt,
    q2.wr_return_amt
FROM (
    SELECT
        row_num,
        cr_returned_date_sk,
        i_category,
        cp_department,
        r_reason_desc,
        ib_lower_bound,
        ws_net_paid_inc_tax,
        sr_return_amt,
        wr_return_amt
    FROM joined
    WHERE cr_returned_date_sk BETWEEN 2451500 AND 2452500
      AND i_current_price <= 100
      AND ib_upper_bound >= 30000
) q2
ORDER BY cr_returned_date_sk
OFFSET 0
LIMIT 100
