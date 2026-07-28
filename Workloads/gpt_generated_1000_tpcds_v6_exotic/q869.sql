WITH web_agg AS (
    SELECT
        'web' AS source_type,
        regexp_extract(i.i_product_name, '^([^ ]+)', 1) AS product_prefix,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        (SELECT AVG(ws2.ws_ext_discount_amt) FROM tpcds.web_sales ws2) AS avg_discount
    FROM tpcds.web_sales ws
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_name LIKE '%Shop%'
      AND sm.sm_code = 'AIR'
      AND regexp_like(i.i_product_name, '^[A-Z]{3}')
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_page cp
          WHERE cp.cp_catalog_page_number = (ws.ws_web_page_sk % 10) + 1
      )
    GROUP BY regexp_extract(i.i_product_name, '^([^ ]+)', 1)
),
store_agg AS (
    SELECT
        'store' AS source_type,
        substr(ca.ca_city, 1, 3) AS product_prefix,
        SUM(sr.sr_net_loss) AS total_net_paid,
        (SELECT AVG(sr2.sr_fee) FROM tpcds.store_returns sr2) AS avg_discount
    FROM tpcds.store_returns sr
    JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE s.s_city LIKE 'New%'
      AND EXISTS (
          SELECT 1
          FROM tpcds.warehouse wh
          WHERE wh.w_county LIKE '%County%'
            AND wh.w_city = s.s_city
      )
    GROUP BY substr(ca.ca_city, 1, 3)
)
SELECT *
FROM (
    SELECT source_type, product_prefix, total_net_paid, avg_discount FROM web_agg
    UNION ALL
    SELECT source_type, product_prefix, total_net_paid, avg_discount FROM store_agg
) combined
ORDER BY total_net_paid DESC
LIMIT 100
