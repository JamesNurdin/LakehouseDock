WITH base1 AS (
    SELECT i.i_brand,
           sm.sm_code,
           cr.cr_return_amount,
           cr.cr_return_tax,
           sr.sr_net_loss,
           ws.ws_net_paid
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    WHERE cr.cr_return_tax > 10.0                     -- filter 1
      AND cr.cr_reversed_charge < 200.0               -- filter 2
      AND sm.sm_code = 'AIR'                          -- filter 3
      AND i.i_brand = 'BrandX'                         -- filter 4
      AND sr.sr_net_loss BETWEEN 100 AND 500          -- filter 5
      AND wp.wp_char_count > 1000                     -- filter 6
      AND ws.ws_quantity >= 5                         -- filter 7
),
base2 AS (
    SELECT i.i_brand,
           sm.sm_code,
           cr.cr_return_amount,
           cr.cr_return_tax,
           sr.sr_net_loss,
           ws.ws_net_paid
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    WHERE cr.cr_return_tax <= 10.0                    -- filter 1b
      AND cr.cr_reversed_charge >= 200.0              -- filter 2b
      AND sm.sm_code = 'SEA'                           -- filter 3b
      AND i.i_brand = 'BrandY'                         -- filter 4b
      AND sr.sr_net_loss > 500                        -- filter 5b
      AND wp.wp_char_count <= 1000                    -- filter 6b
      AND ws.ws_quantity < 5                          -- filter 7b
),
combined AS (
    SELECT i_brand AS brand,
           sm_code AS ship_mode,
           cr_return_amount AS amount,
           cr_return_tax AS tax,
           sr_net_loss AS net_loss,
           ws_net_paid AS net_paid
    FROM base1
    UNION ALL
    SELECT i_brand,
           sm_code,
           cr_return_amount,
           cr_return_tax,
           sr_net_loss,
           ws_net_paid
    FROM base2
),
agg AS (
    SELECT brand,
           ship_mode,
           SUM(amount) AS total_return_amount,
           AVG(tax)   AS avg_return_tax,
           SUM(net_loss) AS total_net_loss,
           SUM(net_paid) AS total_net_paid,
           COUNT(*) AS txn_count
    FROM combined
    GROUP BY ROLLUP (brand, ship_mode)
)
SELECT brand,
       ship_mode,
       total_return_amount,
       avg_return_tax,
       total_net_loss,
       total_net_paid,
       txn_count,
       ROW_NUMBER() OVER (PARTITION BY brand ORDER BY total_return_amount DESC) AS brand_rank
FROM agg
ORDER BY brand, ship_mode
LIMIT 100
