WITH
    store_sample AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    agg_store AS (
        SELECT ss.ss_addr_sk,
               SUM(ss.ss_ext_sales_price) AS store_sales_total,
               SUM(ss.ss_quantity) AS store_qty
        FROM store_sample ss
        WHERE ss.ss_sales_price > 20.00
          AND ss.ss_ext_tax < 500.00
        GROUP BY ss.ss_addr_sk
    ),
    agg_catalog AS (
        SELECT cr.cr_refunded_addr_sk,
               SUM(cr.cr_return_amount) AS catalog_return_amount,
               SUM(cr.cr_return_quantity) AS catalog_return_qty
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 100.00
          AND cr.cr_return_tax < 300.00
        GROUP BY cr.cr_refunded_addr_sk
    ),
    agg_web AS (
        SELECT wr.wr_refunded_addr_sk,
               SUM(wr.wr_return_amt_inc_tax) AS web_return_amount,
               SUM(wr.wr_return_quantity) AS web_return_qty
        FROM web_returns wr
        WHERE wr.wr_return_amt_inc_tax > 50.00
          AND wr.wr_return_ship_cost < 400.00
        GROUP BY wr.wr_refunded_addr_sk
    ),
    store_addr AS (
        SELECT a.ca_address_sk,
               a.ca_city,
               a.ca_state,
               s.store_sales_total,
               s.store_qty
        FROM agg_store s
        JOIN customer_address a
          ON s.ss_addr_sk = a.ca_address_sk
    ),
    web_addr AS (
        SELECT a.ca_address_sk,
               a.ca_city,
               a.ca_state,
               w.web_return_amount,
               w.web_return_qty
        FROM agg_web w
        JOIN customer_address a
          ON w.wr_refunded_addr_sk = a.ca_address_sk
    ),
    full_combined AS (
        SELECT COALESCE(sa.ca_address_sk, wa.ca_address_sk) AS address_sk,
               COALESCE(sa.ca_city, wa.ca_city)           AS city,
               COALESCE(sa.ca_state, wa.ca_state)         AS state,
               sa.store_sales_total,
               sa.store_qty,
               wa.web_return_amount,
               wa.web_return_qty
        FROM store_addr sa
        FULL OUTER JOIN web_addr wa
          ON sa.ca_address_sk = wa.ca_address_sk
    )
SELECT
    fc.address_sk,
    fc.city,
    fc.state,
    fc.store_sales_total,
    fc.store_qty,
    fc.web_return_amount,
    fc.web_return_qty,
    cr.catalog_return_amount,
    cr.catalog_return_qty,
    (COALESCE(fc.store_sales_total, 0) + COALESCE(fc.web_return_amount, 0) + COALESCE(cr.catalog_return_amount, 0)) AS total_amount,
    RANK() OVER (ORDER BY (COALESCE(fc.store_sales_total, 0) + COALESCE(fc.web_return_amount, 0) + COALESCE(cr.catalog_return_amount, 0)) DESC) AS amount_rank,
    CASE WHEN (COALESCE(fc.store_sales_total, 0) + COALESCE(fc.web_return_amount, 0) + COALESCE(cr.catalog_return_amount, 0)) > 5000 THEN 'HIGH' ELSE 'NORMAL' END AS amount_category,
    (SELECT AVG(
                COALESCE(s.store_sales_total, 0) +
                COALESCE(w.web_return_amount, 0) +
                COALESCE(c.catalog_return_amount, 0)
            )
     FROM full_combined s
     LEFT JOIN agg_catalog c ON s.address_sk = c.cr_refunded_addr_sk
     LEFT JOIN agg_web w    ON s.address_sk = w.wr_refunded_addr_sk) AS avg_total_amount
FROM full_combined fc
LEFT JOIN agg_catalog cr
  ON fc.address_sk = cr.cr_refunded_addr_sk
WHERE fc.state = 'CA'
  AND (fc.store_sales_total IS NOT NULL OR fc.web_return_amount IS NOT NULL)
  AND (fc.store_qty IS NULL OR fc.store_qty > 5)
ORDER BY total_amount DESC
LIMIT 100
