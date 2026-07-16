SELECT
    st.s_state,
    ds.d_year AS sale_year,
    ds.d_moy AS sale_month,
    dr.d_year AS return_year,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(cr.cr_order_number) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'No Loss' END AS loss_indicator
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN date_dim ds
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN date_dim dsh
    ON cs.cs_ship_date_sk = dsh.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = ds.d_date_sk
JOIN date_dim dw
    ON ws.ws_ship_date_sk = dw.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = ds.d_date_sk
GROUP BY GROUPING SETS (
    (st.s_state, ds.d_year, ds.d_moy, dr.d_year),
    (st.s_state, ds.d_year, ds.d_moy),
    (st.s_state, ds.d_year),
    (st.s_state),
    ()
)
ORDER BY st.s_state, sale_year, sale_month
