SELECT
    d_ret.d_year,
    d_ret.d_quarter_name,
    cc.cc_name,
    s.s_store_name,
    i.i_category,
    i.i_brand,
    COUNT(cr.cr_order_number) AS total_returns,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_store_credit) AS total_store_credit,
    MIN(d_ret.d_date) AS earliest_return_date,
    MAX(d_ret.d_date) AS latest_return_date
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_ccclosed
    ON cc.cc_closed_date_sk = d_ccclosed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ccclosed.d_date_sk
WHERE d_ret.d_year = 2022
  AND i.i_category IN ('Electronics', 'Books')
GROUP BY
    d_ret.d_year,
    d_ret.d_quarter_name,
    cc.cc_name,
    s.s_store_name,
    i.i_category,
    i.i_brand
ORDER BY total_return_amount DESC
LIMIT 100
