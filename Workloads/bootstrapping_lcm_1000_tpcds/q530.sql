SELECT
    cc.cc_call_center_id,
    cc.cc_city,
    s.s_store_name,
    s.s_city AS store_city,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(cr.cr_return_tax) AS min_return_tax,
    MAX(i.i_current_price) AS max_item_price
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cc.cc_closed_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND i.i_category IN ('Electronics', 'Furniture')
  AND cc.cc_state = s.s_state
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand
HAVING SUM(cr.cr_return_quantity) > 5
ORDER BY total_return_amount DESC
LIMIT 100
