WITH
store_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        d.d_date AS sold_date,
        SUM(ss.ss_net_paid) AS total_store_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_item_sk, d.d_date
),
catalog_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d.d_date AS sold_date,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_item_sk, d.d_date
),
combined AS (
    SELECT
        COALESCE(s.item_sk, c.item_sk) AS item_sk,
        COALESCE(s.sold_date, c.sold_date) AS sold_date,
        s.total_store_net_paid,
        c.total_catalog_net_paid
    FROM store_agg s
    FULL OUTER JOIN catalog_agg c
        ON s.item_sk = c.item_sk
        AND s.sold_date = c.sold_date
)
SELECT DISTINCT
    i.i_item_id,
    i.i_product_name,
    c.sold_date,
    c.total_store_net_paid,
    c.total_catalog_net_paid
FROM combined c
JOIN item i ON i.i_item_sk = c.item_sk
WHERE c.total_store_net_paid > c.total_catalog_net_paid
  AND c.total_store_net_paid > (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = c.item_sk
      )
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y'
      )
UNION ALL
SELECT DISTINCT
    i2.i_item_id,
    i2.i_product_name,
    d2.d_date AS sold_date,
    0.0 AS total_store_net_paid,
    SUM(cr.cr_refunded_cash) AS total_catalog_net_paid
FROM catalog_returns cr
JOIN item i2 ON i2.i_item_sk = cr.cr_item_sk
JOIN date_dim d2 ON d2.d_date_sk = cr.cr_returned_date_sk
WHERE cr.cr_refunded_cash > 0
GROUP BY i2.i_item_id, i2.i_product_name, d2.d_date
ORDER BY total_store_net_paid DESC, total_catalog_net_paid DESC
LIMIT 100
