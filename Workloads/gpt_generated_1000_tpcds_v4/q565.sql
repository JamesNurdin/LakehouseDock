WITH return_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cr.cr_return_quantity > 0
      AND cr.cr_fee < 100
      AND cr.cr_return_ship_cost >= 0
      AND cr.cr_net_loss > 0
    GROUP BY cr.cr_item_sk, cr.cr_reason_sk, cr.cr_returned_date_sk, cr.cr_returned_time_sk, cr.cr_ship_mode_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_ret.d_year AS return_year,
    sm.sm_type,
    r.r_reason_desc,
    ra.total_return_amount,
    ra.cnt_returns,
    SUM(cs.cs_net_paid) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(p.p_cost) AS avg_promo_cost
FROM return_agg ra
JOIN item i
    ON ra.cr_item_sk = i.i_item_sk
JOIN reason r
    ON ra.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_ret
    ON ra.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON ra.cr_returned_time_sk = t_ret.t_time_sk
JOIN ship_mode sm
    ON ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_sales cs
    ON i.i_item_sk = cs.cs_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN web_returns wr
    ON i.i_item_sk = wr.wr_item_sk
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
WHERE d_ret.d_year = 2001
  AND i.i_current_price BETWEEN 20 AND 200
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc NOT LIKE '%unspecified%'
  AND p.p_channel_tv = 'N'
  AND ca_bill.ca_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_net_loss > 5000
    )
GROUP BY i.i_item_id, i.i_product_name, d_ret.d_year, sm.sm_type, r.r_reason_desc, ra.total_return_amount, ra.cnt_returns
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
