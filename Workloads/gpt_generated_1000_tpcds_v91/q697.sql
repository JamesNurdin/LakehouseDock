WITH base_all AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        s.s_store_name,
        w.w_warehouse_name,
        p.p_promo_name,
        d_sr.d_date AS return_date,
        d_sr.d_year AS d_year_return,
        i.i_current_price,
        w.w_gmt_offset,
        p.p_purpose,
        cr.cr_return_amount,
        ws.ws_quantity,
        COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) AS total_net_loss
    FROM
        item i
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
        JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
        JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
        JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
        JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
        JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
)
SELECT
    i_item_id,
    i_item_desc,
    s_store_name,
    w_warehouse_name,
    p_promo_name,
    return_date,
    total_net_loss,
    RANK() OVER (PARTITION BY s_store_name ORDER BY total_net_loss DESC) AS loss_rank
FROM base_all
WHERE d_year_return = 2001
  AND i_current_price BETWEEN 50 AND 300
  AND w_gmt_offset = -5.00
  AND p_purpose = 'Unknown'
  AND cr_return_amount > 20
  AND ws_quantity > 1
UNION
SELECT
    i_item_id,
    i_item_desc,
    s_store_name,
    w_warehouse_name,
    p_promo_name,
    return_date,
    total_net_loss,
    RANK() OVER (PARTITION BY s_store_name ORDER BY total_net_loss DESC) AS loss_rank
FROM base_all
WHERE d_year_return = 2002
  AND i_current_price < 100
  AND w_gmt_offset = -6.00
  AND p_purpose = 'Unknown'
  AND cr_return_amount <= 20
  AND ws_quantity = 1
ORDER BY loss_rank, total_net_loss DESC
LIMIT 100
