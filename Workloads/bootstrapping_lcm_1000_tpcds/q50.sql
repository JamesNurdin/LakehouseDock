SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    wp.wp_web_page_id,
    wp.wp_url,
    dr.d_year AS return_year,
    dr.d_quarter_name AS return_quarter,
    ds.d_year AS store_closed_year,
    dcp.d_year AS page_creation_year,
    dap.d_year AS page_access_year,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    CASE
        WHEN SUM(sr.sr_net_loss) > 0 THEN SUM(wr.wr_net_loss) / SUM(sr.sr_net_loss)
        ELSE NULL
    END AS web_to_store_net_loss_ratio
FROM store_returns sr
JOIN date_dim dr
    ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim dcp
    ON wp.wp_creation_date_sk = dcp.d_date_sk
JOIN date_dim dap
    ON wp.wp_access_date_sk = dap.d_date_sk
WHERE dr.d_year = 2023
  AND s.s_state = 'TX'
  AND wp.wp_type = 'Product'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    wp.wp_web_page_id,
    wp.wp_url,
    dr.d_year,
    dr.d_quarter_name,
    ds.d_year,
    dcp.d_year,
    dap.d_year
ORDER BY total_store_net_loss DESC
LIMIT 100
