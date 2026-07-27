WITH filtered_sales AS (
    SELECT ws_order_number,
           ws_item_sk,
           ws_sold_date_sk,
           ws_quantity,
           ws_net_paid,
           ws_net_profit
    FROM web_sales
    WHERE ws_quantity > 5
      AND ws_net_profit > 1000
)
SELECT
    d.d_year,
    r.r_reason_desc,
    CASE 
        WHEN r.r_reason_id = 'AAAAAAAABBAAAAAA' THEN 'Promo'
        ELSE 'Other'
    END AS reason_category,
    COUNT(DISTINCT fs.ws_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    AVG(sr.sr_return_amt_inc_tax) AS avg_store_return_inc_tax,
    MIN(wr.wr_fee) AS min_web_return_fee,
    MAX(fs.ws_net_paid) AS max_net_paid,
    SUM(CASE WHEN cr.cr_return_tax > 20 THEN cr.cr_return_tax ELSE 0 END) AS total_high_tax_return
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_reason_sk = r.r_reason_sk
JOIN filtered_sales fs
    ON wr.wr_item_sk = fs.ws_item_sk
   AND wr.wr_order_number = fs.ws_order_number
WHERE d.d_year = 2000
  AND d.d_month_seq BETWEEN 1200 AND 1210
  AND cr.cr_return_amount > 100
  AND sr.sr_return_quantity >= 2
  AND wr.wr_fee < 50
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_order_number = fs.ws_order_number
          AND ws2.ws_ship_mode_sk = 3
    )
GROUP BY
    d.d_year,
    r.r_reason_desc,
    CASE 
        WHEN r.r_reason_id = 'AAAAAAAABBAAAAAA' THEN 'Promo'
        ELSE 'Other'
    END
ORDER BY total_catalog_return_amount DESC
LIMIT 100
