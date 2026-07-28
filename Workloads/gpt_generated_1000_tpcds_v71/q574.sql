WITH
    inventory_agg AS (
        SELECT
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        GROUP BY inv_warehouse_sk
    ),
    cat_sales_agg AS (
        SELECT
            cs.cs_bill_customer_sk AS customer_sk,
            cs.cs_warehouse_sk AS warehouse_sk,
            SUM(cs.cs_ext_sales_price) AS cat_sales_total,
            SUM(cs.cs_quantity) AS cat_qty
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 2
        GROUP BY cs.cs_bill_customer_sk, cs.cs_warehouse_sk
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_bill_customer_sk AS customer_sk,
            ws.ws_warehouse_sk AS warehouse_sk,
            MIN(ws.ws_web_site_sk) AS web_site_sk,
            SUM(ws.ws_ext_sales_price) AS web_sales_total,
            SUM(ws.ws_quantity) AS web_qty
        FROM web_sales ws
        WHERE ws.ws_quantity > 1
        GROUP BY ws.ws_bill_customer_sk, ws.ws_warehouse_sk
    ),
    returns_agg AS (
        SELECT
            sr.sr_customer_sk AS customer_sk,
            SUM(sr.sr_net_loss) AS returns_loss,
            SUM(sr.sr_refunded_cash) AS refunded_cash_total
        FROM store_returns sr
        WHERE sr.sr_refunded_cash > 100
        GROUP BY sr.sr_customer_sk
    )
SELECT DISTINCT
    c.c_customer_id,
    c.c_birth_country,
    w.w_warehouse_name,
    iagg.total_qty_on_hand,
    csagg.cat_sales_total,
    wsagg.web_sales_total,
    ragg.returns_loss,
    (csagg.cat_sales_total + wsagg.web_sales_total - COALESCE(ragg.returns_loss, 0)) AS net_sales,
    ROW_NUMBER() OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY (csagg.cat_sales_total + wsagg.web_sales_total - COALESCE(ragg.returns_loss, 0)) DESC
    ) AS sales_rank,
    CASE
        WHEN (csagg.cat_sales_total + wsagg.web_sales_total) > 20000 THEN 'VIP'
        ELSE 'REGULAR'
    END AS customer_tier,
    wp.wp_url
FROM customer c
INNER JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
INNER JOIN cat_sales_agg csagg
    ON csagg.customer_sk = c.c_customer_sk
INNER JOIN web_sales_agg wsagg
    ON wsagg.customer_sk = c.c_customer_sk
    AND wsagg.warehouse_sk = csagg.warehouse_sk
INNER JOIN returns_agg ragg
    ON ragg.customer_sk = c.c_customer_sk
INNER JOIN warehouse w
    ON w.w_warehouse_sk = csagg.warehouse_sk
INNER JOIN inventory_agg iagg
    ON iagg.inv_warehouse_sk = w.w_warehouse_sk
INNER JOIN web_site wsit
    ON wsit.web_site_sk = wsagg.web_site_sk
INNER JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'PHILIPPINES'
  AND w.w_street_name = 'Oak Ninth'
  AND iagg.total_qty_on_hand > 5000
  AND csagg.cat_qty > 5
  AND wsagg.web_qty > 3
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs_check
        WHERE cs_check.cs_bill_customer_sk = c.c_customer_sk
          AND cs_check.cs_ext_discount_amt > 0
      )
ORDER BY net_sales DESC
LIMIT 100
