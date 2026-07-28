WITH joined_data AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_profit,
    ws.ws_list_price,
    ws.ws_ext_wholesale_cost,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    i.i_size,
    i.i_manufact_id,
    wp.wp_url,
    wp.wp_rec_end_date,
    wp.wp_access_date_sk,
    wsite.web_name,
    wsite.web_state,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cp.cp_catalog_number,
    cp.cp_department,
    wr.wr_return_amt,
    wr.wr_net_loss
  FROM web_sales ws
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE ws.ws_list_price > 100
    AND ws.ws_ext_wholesale_cost BETWEEN 5000 AND 7000
    AND wp.wp_rec_end_date >= DATE '2000-01-01'
    AND wp.wp_access_date_sk IN (2452646, 2452608, 2452555)
    AND i.i_size IN ('economy', 'large')
    AND wsite.web_state = 'CA'
)
SELECT
  jd.ws_order_number,
  jd.i_item_id,
  jd.i_brand,
  jd.i_category,
  jd.i_size,
  jd.i_manufact_id,
  jd.web_name,
  jd.web_state,
  jd.wp_url AS sale_page_url,
  jd.ws_quantity,
  jd.ws_sales_price,
  jd.ws_net_profit,
  jd.cp_catalog_number,
  jd.cp_department,
  jd.cr_return_amount,
  jd.cr_net_loss,
  jd.wr_return_amt,
  jd.wr_net_loss,
  (COALESCE(jd.cr_return_amount, 0) + COALESCE(jd.wr_return_amt, 0)) AS total_return_amount,
  (COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) AS total_net_loss,
  CASE
    WHEN (COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) > 0 THEN 'Loss'
    ELSE 'Profit'
  END AS profit_status,
  RANK() OVER (PARTITION BY jd.web_name ORDER BY jd.ws_net_profit DESC) AS profit_rank_within_site,
  DENSE_RANK() OVER (PARTITION BY jd.i_brand ORDER BY jd.ws_quantity DESC) AS qty_rank_within_brand
FROM joined_data jd
ORDER BY jd.web_name, profit_rank_within_site
LIMIT 100
