WITH
  store_agg AS (
    SELECT
      c.c_customer_sk AS c_customer_sk,
      hd.hd_demo_sk AS hd_demo_sk,
      SUM(ss.ss_net_paid_inc_tax) AS store_sales_net_paid_inc_tax,
      SUM(ss.ss_net_profit) AS store_net_profit,
      COUNT(DISTINCT ss.ss_item_sk) AS store_distinct_items
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, hd.hd_demo_sk
  ),
  web_agg AS (
    SELECT
      c.c_customer_sk AS c_customer_sk,
      hd.hd_demo_sk AS hd_demo_sk,
      SUM(ws.ws_net_paid_inc_tax) AS web_sales_net_paid_inc_tax,
      SUM(ws.ws_net_profit) AS web_net_profit,
      COUNT(DISTINCT ws.ws_item_sk) AS web_distinct_items
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, hd.hd_demo_sk
  ),
  returns_agg AS (
    SELECT
      c.c_customer_sk AS c_customer_sk,
      hd.hd_demo_sk AS hd_demo_sk,
      SUM(cr.cr_net_loss) AS total_return_loss,
      COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, hd.hd_demo_sk
  ),
  web_page_agg AS (
    SELECT
      c.c_customer_sk AS c_customer_sk,
      hd.hd_demo_sk AS hd_demo_sk,
      COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages_visited,
      SUM(wp.wp_image_count) AS total_images_on_pages
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, hd.hd_demo_sk
  )
SELECT
  COALESCE(sa.c_customer_sk, wa.c_customer_sk, ra.c_customer_sk, wpag.c_customer_sk) AS customer_sk,
  COALESCE(sa.hd_demo_sk, wa.hd_demo_sk, ra.hd_demo_sk, wpag.hd_demo_sk) AS demo_sk,
  COALESCE(sa.store_sales_net_paid_inc_tax, 0) AS store_sales_net_paid_inc_tax,
  COALESCE(sa.store_net_profit, 0) AS store_net_profit,
  COALESCE(wa.web_sales_net_paid_inc_tax, 0) AS web_sales_net_paid_inc_tax,
  COALESCE(wa.web_net_profit, 0) AS web_net_profit,
  COALESCE(ra.total_return_loss, 0) AS total_return_loss,
  COALESCE(sa.store_distinct_items, 0) AS store_distinct_items,
  COALESCE(wa.web_distinct_items, 0) AS web_distinct_items,
  COALESCE(ra.return_count, 0) AS return_count,
  COALESCE(wpag.distinct_pages_visited, 0) AS distinct_pages_visited,
  COALESCE(wpag.total_images_on_pages, 0) AS total_images_on_pages
FROM store_agg sa
FULL OUTER JOIN web_agg wa
  ON sa.c_customer_sk = wa.c_customer_sk
  AND sa.hd_demo_sk = wa.hd_demo_sk
FULL OUTER JOIN returns_agg ra
  ON COALESCE(sa.c_customer_sk, wa.c_customer_sk) = ra.c_customer_sk
  AND COALESCE(sa.hd_demo_sk, wa.hd_demo_sk) = ra.hd_demo_sk
FULL OUTER JOIN web_page_agg wpag
  ON COALESCE(sa.c_customer_sk, wa.c_customer_sk, ra.c_customer_sk) = wpag.c_customer_sk
  AND COALESCE(sa.hd_demo_sk, wa.hd_demo_sk, ra.hd_demo_sk) = wpag.hd_demo_sk
ORDER BY total_return_loss DESC
LIMIT 100
