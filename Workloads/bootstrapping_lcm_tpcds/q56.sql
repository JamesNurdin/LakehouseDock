SELECT
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    s.s_store_name,
    s.s_market_desc,
    ss.ss_ticket_number,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_quantity,
    ws.web_name,
    ws.web_country,
    ws.web_gmt_offset,
    CASE 
        WHEN ss.ss_ext_sales_price = 0 THEN NULL
        ELSE ss.ss_net_profit / ss.ss_ext_sales_price
    END AS profit_margin
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_store_sk = s.s_store_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE cr.cr_return_quantity > 0
ORDER BY cr.cr_return_amount DESC
LIMIT 100
