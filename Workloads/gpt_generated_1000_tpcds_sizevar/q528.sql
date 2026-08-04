WITH
  store_part AS (
    SELECT
      p.p_promo_name        AS promo_name,
      ca.ca_state           AS region,
      ss.ss_net_paid        AS net_paid,
      ps.promo_state_sales  AS extra_metric,
      ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY ss.ss_net_paid DESC) AS rank_in_promo,
      CAST(FALSE AS BOOLEAN) AS has_content_page
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
      SELECT SUM(ss2.ss_ext_sales_price) AS promo_state_sales
      FROM store_sales ss2
      WHERE ss2.ss_promo_sk = ss.ss_promo_sk
        AND ss2.ss_addr_sk = ss.ss_addr_sk
    ) AS ps
    WHERE p.p_promo_id NOT IN (
            SELECT p2.p_promo_id
            FROM promotion p2
            WHERE p2.p_discount_active = 'Y'
          )
      AND ss.ss_net_paid > (
            SELECT AVG(ssi.ss_net_paid)
            FROM store_sales ssi
          )
      AND ss.ss_ext_tax > 5
  ),
  web_part AS (
    SELECT
      p.p_promo_name        AS promo_name,
      w.w_state             AS region,
      ws.ws_net_paid        AS net_paid,
      ws.ws_ext_sales_price AS extra_metric,
      ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY ws.ws_net_paid DESC) AS rank_in_promo,
      EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
          AND wp.wp_type = 'content'
      ) AS has_content_page
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_promo_id NOT IN (
            SELECT p2.p_promo_id
            FROM promotion p2
            WHERE p2.p_discount_active = 'Y'
          )
      AND ws.ws_net_paid > 0
      AND ws.ws_ext_sales_price > (
            SELECT AVG(wsi.ws_ext_sales_price)
            FROM web_sales wsi
          )
  )
SELECT
  promo_name,
  region,
  net_paid,
  extra_metric,
  rank_in_promo,
  has_content_page
FROM store_part
WHERE promo_name NOT IN (
        SELECT p3.p_promo_name
        FROM promotion p3
        WHERE p3.p_promo_name LIKE 'Clearance%'
      )
UNION
SELECT
  promo_name,
  region,
  net_paid,
  extra_metric,
  rank_in_promo,
  has_content_page
FROM web_part
WHERE promo_name NOT IN (
        SELECT p3.p_promo_name
        FROM promotion p3
        WHERE p3.p_promo_name LIKE 'Clearance%'
      )
ORDER BY promo_name, region, rank_in_promo
LIMIT 100
