WITH raw AS (
  SELECT
    i.i_category,
    wsite.web_name,
    sr.sr_net_loss AS store_loss,
    cr.cr_net_loss AS catalog_loss,
    wr.wr_net_loss AS web_loss,
    ws.ws_net_paid AS sales
  FROM item i
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
  JOIN promotion p ON p.p_promo_sk = ws.ws_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
  JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
  JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
  JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
  JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
  JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
  LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
  JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
  JOIN date_dim d_wsite_open ON wsite.web_open_date_sk = d_wsite_open.d_date_sk
  JOIN date_dim d_wsite_close ON wsite.web_close_date_sk = d_wsite_close.d_date_sk
  JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
),
agg AS (
  SELECT
    i_category,
    web_name,
    SUM(store_loss) AS total_store_loss,
    SUM(catalog_loss) AS total_catalog_loss,
    SUM(COALESCE(web_loss, 0)) AS total_web_loss,
    SUM(sales) AS total_sales,
    SUM(sales) - (SUM(store_loss) + SUM(catalog_loss) + SUM(COALESCE(web_loss, 0))) AS net_contribution
  FROM raw
  GROUP BY i_category, web_name
  HAVING SUM(sales) > 100000
)
SELECT
  i_category,
  web_name,
  total_store_loss,
  total_catalog_loss,
  total_web_loss,
  total_sales,
  net_contribution,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY net_contribution DESC
LIMIT 100
