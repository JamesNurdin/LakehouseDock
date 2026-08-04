/*
Goal: Analyze sales and returns performance for the year 1999, focusing on items sold by unit 'Dozen' in California for the 'Sports' department, and limited to income bands starting at 10,000. The query joins all eight selected TPC‑DS tables, filters on realistic literals, keeps only rows that have at least one matching return (EXISTS), calculates subtotals and a grand total with GROUP BY ROLLUP, uses a LATERAL subquery to compute the average quantity sold per brand, and returns the top‑5 brands per year ranked by total sales. Results are ordered and paginated (first 100 rows).
*/
WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        wr.wr_returned_date_sk,
        wr.wr_return_amt,
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_brand,
        i.i_units,
        i.i_current_price,
        ca.ca_state,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cp.cp_department
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_item_sk = i.i_item_sk
     AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
     AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp
      ON cp.cp_start_date_sk = d.d_date_sk
),
filtered AS (
    SELECT *
    FROM base
    WHERE d_year = 1999
      AND i_units = 'Dozen'
      AND ib_lower_bound >= 10000
      AND ca_state = 'CA'
      AND cp_department = 'Sports'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_item_sk = ss_item_sk
            AND wr2.wr_returned_date_sk = ss_sold_date_sk
      )
),
agg AS (
    SELECT
        d_year,
        i_brand,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(wr_return_amt)      AS total_returns,
        COUNT(DISTINCT ss_item_sk) AS distinct_items_sold,
        AVG(ss_quantity)        AS avg_quantity,
        MAX(ss_net_profit)      AS max_profit
    FROM filtered
    GROUP BY ROLLUP (d_year, i_brand)
),
ranked AS (
    SELECT
        a.*, 
        ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS rn
    FROM agg a
)
SELECT
    r.d_year,
    r.i_brand,
    r.total_sales,
    r.total_returns,
    r.distinct_items_sold,
    r.avg_quantity,
    r.max_profit,
    l.avg_qty_per_brand
FROM ranked r
CROSS JOIN LATERAL (
    SELECT AVG(ss_quantity) AS avg_qty_per_brand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_brand = r.i_brand
) l
WHERE r.rn <= 5
ORDER BY r.d_year ASC, r.total_sales DESC
OFFSET 0 LIMIT 100
