SELECT
    cr.cr_order_number AS return_order_number,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_return_tax,
    cr.cr_net_loss,
    dd_ret.d_date AS return_date,
    dd_ret.d_year AS return_year,
    ws.ws_order_number AS web_order_number,
    ws.ws_sales_price,
    ws.ws_quantity,
    ws.ws_net_profit,
    dd_ship.d_date AS ship_date,
    dd_ship.d_year AS ship_year,
    p.p_promo_name,
    p.p_discount_active,
    p.p_cost,
    dd_promo_start.d_date AS promo_start_date,
    dd_promo_end.d_date AS promo_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_country,
    s.s_tax_percentage,
    (cr.cr_return_amount - ws.ws_sales_price) AS return_vs_sales_diff,
    (ws.ws_net_profit - cr.cr_net_loss) AS profit_vs_loss_diff,
    ROW_NUMBER() OVER (ORDER BY cr.cr_return_amount DESC) AS return_rank
FROM catalog_returns cr
JOIN date_dim dd_ret
  ON cr.cr_returned_date_sk = dd_ret.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = dd_ret.d_date_sk
JOIN date_dim dd_ship
  ON ws.ws_ship_date_sk = dd_ship.d_date_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim dd_promo_start
  ON p.p_start_date_sk = dd_promo_start.d_date_sk
JOIN date_dim dd_promo_end
  ON p.p_end_date_sk = dd_promo_end.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = dd_ret.d_date_sk
ORDER BY cr.cr_return_amount DESC
LIMIT 100
