WITH wr AS (
    SELECT *
    FROM web_returns
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_item_id,
    i.i_product_name,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(wr.wr_return_quantity) DESC) AS rn
FROM wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk                                 -- 1
JOIN item i ON wr.wr_item_sk = i.i_item_sk                                                -- 2
JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk       -- 3
JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk       -- 4
JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk       -- 5
JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk       -- 6
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk                -- 7
LEFT JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk                     -- 8
LEFT JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk                       -- 9
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d.d_date_sk                                                  --10
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_item_id,
    i.i_product_name,
    cd_ref.cd_gender,
    cd_ret.cd_gender,
    hd_ref.hd_buy_potential,
    hd_ret.hd_buy_potential
HAVING SUM(wr.wr_return_quantity) > 0
ORDER BY d.d_year DESC, total_return_qty DESC
LIMIT 100
