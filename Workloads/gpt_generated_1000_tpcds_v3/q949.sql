WITH inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    s.s_division_name,
    d_ret.d_date,
    t.t_shift,
    p.p_promo_name,
    p.p_cost,
    inv_agg.total_quantity_on_hand,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    AVG(wr.wr_return_amt) AS avg_return_amt
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN inv_agg
    ON inv_agg.inv_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_ret.d_year = 2002
  AND t.t_shift = 'first'
  AND s.s_market_manager = 'Dennis Glass'
  AND p.p_discount_active = 'Y'
  AND wp.wp_max_ad_count > 1
  AND r.r_reason_desc LIKE '%defect%'
  AND cc.cc_gmt_offset > 0
  AND inv_agg.total_quantity_on_hand > 500
GROUP BY
    s.s_division_name,
    d_ret.d_date,
    t.t_shift,
    p.p_promo_name,
    p.p_cost,
    inv_agg.total_quantity_on_hand
HAVING SUM(wr.wr_net_loss) > 10000
ORDER BY total_net_loss DESC
LIMIT 100
