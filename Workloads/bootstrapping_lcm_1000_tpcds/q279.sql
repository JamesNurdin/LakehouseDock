SELECT
    st.s_store_id,
    st.s_state,
    d_ret.d_year,
    d_ret.d_quarter_seq,
    cd_refunded.cd_credit_rating,
    cd_returning.cd_gender,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_return_quantity) AS total_return_quantity,
    SUM(s.cs_sales_price * s.cs_quantity) AS total_sales_amount,
    SUM(s.cs_quantity) AS total_sales_quantity,
    AVG(cd_refunded.cd_purchase_estimate) AS avg_refund_purchase_estimate,
    SUM(r.cr_net_loss) AS total_net_loss,
    SUM(s.cs_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(s.cs_net_profit) = 0 THEN NULL
        ELSE SUM(r.cr_net_loss) / SUM(s.cs_net_profit)
    END AS loss_to_profit_ratio,
    COUNT(DISTINCT r.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT s.cs_order_number) AS distinct_sales_orders
FROM catalog_returns r
JOIN date_dim d_ret
    ON r.cr_returned_date_sk = d_ret.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = d_ret.d_date_sk
JOIN catalog_sales s
    ON r.cr_item_sk = s.cs_item_sk
   AND r.cr_order_number = s.cs_order_number
JOIN date_dim d_sold
    ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON s.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_refunded
    ON r.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON r.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_demographics cd_bill
    ON s.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
WHERE d_ret.d_year = 2001
  AND st.s_state = 'CA'
GROUP BY
    st.s_store_id,
    st.s_state,
    d_ret.d_year,
    d_ret.d_quarter_seq,
    cd_refunded.cd_credit_rating,
    cd_returning.cd_gender
HAVING SUM(r.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
