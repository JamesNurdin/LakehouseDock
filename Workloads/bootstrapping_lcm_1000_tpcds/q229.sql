SELECT
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    i.i_category,
    i.i_brand,
    s.s_state,
    s.s_city,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    CASE 
        WHEN cd_ref.cd_purchase_estimate < 500 THEN 'Low'
        WHEN cd_ref.cd_purchase_estimate < 2000 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_category,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    SUM(cr.cr_store_credit) AS total_store_credit,
    SUM(cr.cr_reversed_charge) AS total_reversed_charge,
    SUM(cr.cr_return_amount) / NULLIF(SUM(i.i_current_price * cr.cr_return_quantity), 0) AS return_to_sales_ratio
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND i.i_category IS NOT NULL
  AND s.s_state IS NOT NULL
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    i.i_category,
    i.i_brand,
    s.s_state,
    s.s_city,
    cd_ref.cd_gender,
    cd_ret.cd_gender,
    CASE 
        WHEN cd_ref.cd_purchase_estimate < 500 THEN 'Low'
        WHEN cd_ref.cd_purchase_estimate < 2000 THEN 'Medium'
        ELSE 'High'
    END
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
