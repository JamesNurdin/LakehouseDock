SELECT
    d.d_year,
    d.d_quarter_seq,
    cd_ref.cd_gender,
    cd_ret.cd_marital_status,
    s.s_state,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_amount ELSE 0 END) AS high_qty_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_fee + cr.cr_store_credit) AS total_fees_and_credits,
    SUM(cr.cr_return_tax * 1.10) AS total_return_tax_with_vat,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_net_loss) / NULLIF(COUNT(*), 0) AS avg_net_loss_per_return
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    cd_ref.cd_gender,
    cd_ret.cd_marital_status,
    s.s_state,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
