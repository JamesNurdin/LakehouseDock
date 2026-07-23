/*
Goal: Identify the top-selling items across store and web channels for the year 2001, adjusting net profit for catalog returns, only for items that had inventory on hand, and filter to high‑profit items.
*/
WITH store_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
          WHERE inv.inv_item_sk = i.i_item_sk
            AND d_inv.d_year = d.d_year
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year
),
web_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
          WHERE inv.inv_item_sk = i.i_item_sk
            AND d_inv.d_year = d.d_year
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year
),
returns_agg AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, d.d_year
)
SELECT
    agg.i_item_id,
    agg.i_product_name,
    agg.d_year,
    SUM(agg.total_net_paid) AS total_net_paid,
    SUM(agg.total_net_profit) AS total_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    SUM(agg.total_net_profit) - COALESCE(r.total_return_amount, 0) AS net_profit_after_returns,
    SUM(agg.distinct_customers) AS distinct_customers,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = agg.i_item_sk
    ) AS avg_store_net_profit_all_years
FROM (
    SELECT i_item_sk, i_item_id, i_product_name, d_year, total_net_paid, total_net_profit, distinct_customers
    FROM store_sales_agg
    UNION ALL
    SELECT i_item_sk, i_item_id, i_product_name, d_year, total_net_paid, total_net_profit, distinct_customers
    FROM web_sales_agg
) agg
LEFT JOIN returns_agg r
    ON agg.i_item_sk = r.i_item_sk
   AND agg.d_year = r.d_year
GROUP BY agg.i_item_id, agg.i_product_name, agg.d_year, agg.i_item_sk, r.total_return_amount
HAVING SUM(agg.total_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
