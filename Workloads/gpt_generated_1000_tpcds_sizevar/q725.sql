WITH
    inv_agg AS (
        SELECT
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_qty,
            COUNT(*) AS inv_rows
        FROM inventory
        WHERE inv_quantity_on_hand > 600
        GROUP BY inv_date_sk
    ),
    page_agg AS (
        SELECT
            cp_start_date_sk AS date_sk,
            cp_catalog_number,
            COUNT(*) AS page_rows
        FROM catalog_page
        WHERE cp_catalog_number IN (10, 14)
          AND cp_end_date_sk > 2451000
        GROUP BY cp_start_date_sk, cp_catalog_number
    ),
    sales_agg AS (
        SELECT
            ss_sold_date_sk,
            SUM(ss_ext_sales_price) AS sum_sales,
            COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
            SUM(ss_net_profit) AS total_profit
        FROM store_sales TABLESAMPLE BERNOULLI (10)
        WHERE ss_quantity > 2
          AND ss_sold_date_sk BETWEEN 2450900 AND 2451200
        GROUP BY ss_sold_date_sk
        HAVING SUM(ss_ext_sales_price) > 1000
    ),
    returns_agg AS (
        SELECT
            cr_returned_date_sk,
            SUM(cr_return_amount) AS sum_return_amount,
            COUNT(DISTINCT cr_refunded_customer_sk) AS distinct_refunded_customers,
            SUM(cr_net_loss) AS total_net_loss
        FROM catalog_returns
        WHERE cr_return_quantity < 20
          AND cr_returned_date_sk BETWEEN 2450900 AND 2451200
        GROUP BY cr_returned_date_sk
    )
SELECT
    d.d_year,
    SUM(i.total_qty)               AS inventory_qty,
    SUM(p.page_rows)               AS catalog_pages,
    SUM(s.sum_sales)               AS sales_amount,
    SUM(r.sum_return_amount)       AS return_amount,
    SUM(s.distinct_customers)      AS distinct_customers,
    SUM(r.distinct_refunded_customers) AS distinct_refunded_customers,
    SUM(s.total_profit) - SUM(r.total_net_loss) AS net_contribution
FROM inv_agg i
FULL OUTER JOIN page_agg p ON i.inv_date_sk = p.date_sk
LEFT JOIN date_dim d ON d.d_date_sk = COALESCE(i.inv_date_sk, p.date_sk)
LEFT JOIN sales_agg s ON s.ss_sold_date_sk = d.d_date_sk
LEFT JOIN returns_agg r ON r.cr_returned_date_sk = d.d_date_sk
WHERE (d.d_year = 2001 OR d.d_year IS NULL)            -- keep year subtotal rows
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_returned_date_sk = s.ss_sold_date_sk
    )
GROUP BY ROLLUP (d.d_year)
ORDER BY d.d_year DESC NULLS LAST
LIMIT 100
