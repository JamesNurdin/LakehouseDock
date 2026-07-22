WITH sales_by_date AS (
    SELECT
        d.d_date_sk,
        d.d_date_id,
        d.d_year,
        d.d_day_name,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit,
        count(distinct cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(d.d_day_name, '^T.*')
      AND d.d_day_name LIKE 'T%'
    GROUP BY d.d_date_sk, d.d_date_id, d.d_year, d.d_day_name
),
returns_by_date AS (
    SELECT
        d.d_date_sk,
        sum(sr.sr_net_loss) AS total_return_loss,
        count(distinct sr.sr_ticket_number) AS distinct_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(d.d_holiday, 'TRUE|FALSE')
    GROUP BY d.d_date_sk
)
SELECT DISTINCT
    CONCAT(CAST(s.d_year AS VARCHAR), '-', SUBSTR(s.d_day_name, 1, 3)) AS year_day_abbrev,
    regexp_extract(s.d_date_id, '(\\d{4})', 1) AS extracted_year_from_date_id,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.distinct_orders,
    COALESCE(r.distinct_returns, 0) AS distinct_returns,
    (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = 12345) AS item_sales_count
FROM sales_by_date s
LEFT JOIN returns_by_date r ON s.d_date_sk = r.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_returned_date_sk = s.d_date_sk
      AND sr2.sr_return_amt > 100.00
)
ORDER BY s.total_sales DESC
LIMIT 100
