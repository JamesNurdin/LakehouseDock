SELECT
    d.d_fy_year,
    d.d_fy_quarter_seq,
    i.i_category,
    i.i_brand,
    s.s_market_id,
    CASE WHEN s.s_tax_percentage > 5 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_category,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss) AS net_loss_diff,
    CASE WHEN SUM(wr.wr_return_amt) = 0 THEN NULL
         ELSE SUM(sr.sr_return_amt) / SUM(wr.wr_return_amt) END AS store_to_web_ratio,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    MAX(CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END) AS has_holiday
FROM date_dim d
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON i.i_item_sk = sr.sr_item_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                     AND wr.wr_item_sk = i.i_item_sk
JOIN store s ON s.s_store_sk = sr.sr_store_sk
JOIN date_dim dc ON s.s_closed_date_sk = dc.d_date_sk
GROUP BY
    d.d_fy_year,
    d.d_fy_quarter_seq,
    i.i_category,
    i.i_brand,
    s.s_market_id,
    CASE WHEN s.s_tax_percentage > 5 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END
ORDER BY total_return_amt DESC
LIMIT 100
