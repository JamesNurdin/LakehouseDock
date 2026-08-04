WITH base AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_returned_time_sk,
    cr.cr_item_sk,
    cr.cr_refunded_customer_sk,
    cr.cr_net_loss,
    wr.wr_returned_date_sk,
    wr.wr_returned_time_sk,
    wr.wr_net_loss,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    i.i_item_sk,
    i.i_brand,
    w.w_warehouse_sk,
    w.w_country,
    r.r_reason_sk,
    r.r_reason_desc,
    d_ret.d_year,
    t_ret.t_am_pm,
    inv.inv_quantity_on_hand,
    wp.wp_web_page_sk,
    r2.r_reason_sk AS r2_reason_sk,
    wp2.wp_web_page_sk AS wp2_web_page_sk
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
                 AND inv.inv_date_sk = d_ret.d_date_sk
  LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                       AND ws.ws_warehouse_sk = w.w_warehouse_sk
                       AND ws.ws_sold_date_sk = d_ret.d_date_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
  LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
  LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d_ret.d_year = 2001
    AND w.w_country = 'United States'
    AND i.i_brand = 'Brand#45'
    AND t_ret.t_am_pm = 'PM'
    AND r.r_reason_desc LIKE '%damaged%'
)
SELECT
  customer_sk,
  first_name,
  last_name,
  total_loss,
  loss_category,
  distinct_return_reasons,
  distinct_web_pages,
  inventory_on_hand,
  ROW_NUMBER() OVER (ORDER BY total_loss DESC) AS loss_rank
FROM (
  SELECT
    c_customer_sk AS customer_sk,
    c_first_name AS first_name,
    c_last_name AS last_name,
    SUM(cr_net_loss) + SUM(COALESCE(wr_net_loss, 0)) AS total_loss,
    CASE WHEN SUM(cr_net_loss) > 0 THEN 'CatalogLoss' ELSE 'NoCatalogLoss' END AS loss_category,
    COUNT(DISTINCT r_reason_sk) AS distinct_return_reasons,
    COUNT(DISTINCT wp_web_page_sk) AS distinct_web_pages,
    (
      SELECT SUM(inv2.inv_quantity_on_hand)
      FROM inventory inv2
      WHERE inv2.inv_item_sk = i_item_sk
        AND inv2.inv_warehouse_sk = w_warehouse_sk
    ) AS inventory_on_hand
  FROM base
  WHERE cr_net_loss > 0
  GROUP BY c_customer_sk, c_first_name, c_last_name, i_item_sk, w_warehouse_sk, wp_web_page_sk, r_reason_sk

  UNION DISTINCT

  SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    SUM(COALESCE(cr_net_loss, 0)) + SUM(wr_net_loss) AS total_loss,
    CASE WHEN SUM(wr_net_loss) > 0 THEN 'WebLoss' ELSE 'NoWebLoss' END AS loss_category,
    COUNT(DISTINCT r2_reason_sk) AS distinct_return_reasons,
    COUNT(DISTINCT wp2_web_page_sk) AS distinct_web_pages,
    (
      SELECT SUM(inv2.inv_quantity_on_hand)
      FROM inventory inv2
      WHERE inv2.inv_item_sk = i_item_sk
        AND inv2.inv_warehouse_sk = w_warehouse_sk
    ) AS inventory_on_hand
  FROM base
  WHERE wr_net_loss > 0
  GROUP BY c_customer_sk, c_first_name, c_last_name, i_item_sk, w_warehouse_sk, wp2_web_page_sk, r2_reason_sk
) AS unioned
ORDER BY loss_rank
LIMIT 100
