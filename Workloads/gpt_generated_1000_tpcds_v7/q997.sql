WITH base AS (
  SELECT
    d.d_date_sk,
    d.d_year,
    d.d_month_seq,
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_catalog_number,
    cr.cr_return_amount,
    sr.sr_net_loss,
    ws.ws_net_profit,
    p.p_promo_name,
    p.p_discount_active,
    i.inv_quantity_on_hand,
    r.r_reason_desc,
    wr.wr_return_quantity,
    wr.wr_return_amt
  FROM tpcds.date_dim d
  LEFT JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
  LEFT JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  LEFT JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wr.wr_order_number = ws.ws_order_number
  LEFT JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
agg AS (
  SELECT
    cp_catalog_page_id,
    cp_department,
    p_promo_name,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(sr_net_loss) AS total_store_loss
  FROM base
  WHERE d_year = 2001
    AND d_month_seq BETWEEN 1200 AND 1300
    AND cp_department = 'Books'
    AND p_discount_active = 'Y'
    AND inv_quantity_on_hand > 0
  GROUP BY cp_catalog_page_id, cp_department, p_promo_name
  HAVING SUM(ws_net_profit) > 1000
)
SELECT
  cp_catalog_page_id,
  cp_department,
  p_promo_name,
  total_catalog_return_amount,
  total_web_profit,
  total_store_loss,
  ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_web_profit DESC) AS profit_rank
FROM agg
ORDER BY cp_department, profit_rank
LIMIT 100
