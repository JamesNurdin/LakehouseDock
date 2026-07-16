SELECT
  ROW_NUMBER() OVER (ORDER BY total_store_net_loss DESC) AS store_loss_rank,
  d_year,
  s_store_id,
  s_market_manager,
  catalog_order_cnt,
  total_catalog_net_loss,
  total_store_net_loss,
  avg_page_image_cnt,
  max_page_ad_cnt
FROM (
  SELECT
    d.d_year,
    s.s_store_id,
    s.s_market_manager,
    COUNT(DISTINCT c.cr_order_number) AS catalog_order_cnt,
    SUM(c.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    AVG(wp.wp_image_count) AS avg_page_image_cnt,
    MAX(wp.wp_max_ad_count) AS max_page_ad_cnt
  FROM catalog_returns c
  JOIN date_dim d ON c.cr_returned_date_sk = d.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                       AND sr.sr_store_sk = s.s_store_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  GROUP BY d.d_year, s.s_store_id, s.s_market_manager
) agg
ORDER BY store_loss_rank
LIMIT 20
