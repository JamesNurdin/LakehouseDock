WITH joined_data AS (
    SELECT
        cr.cr_item_sk,
        i.i_item_id,
        i.i_current_price,
        r.r_reason_desc,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_return_amt,
        ws.ws_ext_sales_price,
        w.web_site_id,
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451000 AND 2452000
      AND i.i_current_price > 20
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_upper_bound <= 100000
      AND w.web_class = 'Unknown'
)
SELECT
    i_item_id,
    hd_income_band_sk,
    SUM(cr_return_quantity) AS total_return_qty,
    SUM(sr_return_amt) AS total_store_return_amt,
    SUM(ws_ext_sales_price) AS total_sales,
    CASE
        WHEN SUM(cr_net_loss) > 500 THEN 'High Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    ROW_NUMBER() OVER (
        PARTITION BY hd_income_band_sk
        ORDER BY SUM(sr_return_amt) DESC
    ) AS rank_by_store_return
FROM joined_data
GROUP BY i_item_id, hd_income_band_sk
HAVING SUM(sr_return_amt) > 100
ORDER BY rank_by_store_return ASC, total_sales DESC
LIMIT 100
