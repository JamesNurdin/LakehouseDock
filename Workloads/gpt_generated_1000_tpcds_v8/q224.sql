/*
  Goal: Identify stores with their total net sales and return amounts for the year 2001, then filter out stores that also appear in a full outer join of stores and returns (i.e., keep only stores whose sales summary is not reproduced by the full‑outer‑join view). The query demonstrates deep‑chain joins across all selected TPC‑DS tables, re‑uses the DATE_DIM table under three different aliases, applies a FULL OUTER JOIN, uses a CTE, EXCEPT, ordering, offset and fetch pagination, and limits the final output.
*/
WITH
-- 1️⃣ Deep‑chain aggregation across all 11 tables
sales_agg AS (
    SELECT
        s.s_store_id,
        SUM(cs.cs_net_paid)                         AS total_sales,
        SUM(cr.cr_return_amount)                    AS total_return_amount,
        COUNT(DISTINCT cs.cs_order_number)          AS order_cnt
    FROM store_returns sr
    JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk                -- join 1
    JOIN item i1 ON sr.sr_item_sk = i1.i_item_sk                              -- join 2
    JOIN customer_address ca1 ON sr.sr_addr_sk = ca1.ca_address_sk           -- join 3
    JOIN store s ON sr.sr_store_sk = s.s_store_sk                             -- join 4
    JOIN catalog_sales cs ON cs.cs_item_sk = i1.i_item_sk                     -- join 5
    JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk                     -- join 6
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk       -- join 7
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk             -- join 8
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk                         -- join 9
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number       -- join 10
    JOIN date_dim d3 ON cr.cr_returned_date_sk = d3.d_date_sk                 -- join 11
    JOIN web_page wp ON wp.wp_creation_date_sk = d3.d_date_sk                 -- join 12
    WHERE d1.d_year = 2001 AND d2.d_year = 2001
    GROUP BY s.s_store_id
),
-- 2️⃣ Full outer join of STORE and STORE_RETURNS (re‑using STORE and STORE_RETURNS under new aliases)
store_full AS (
    SELECT
        s2.s_store_id,
        COALESCE(SUM(sr2.sr_return_quantity), 0) AS total_return_qty
    FROM store s2
    FULL OUTER JOIN store_returns sr2 ON sr2.sr_store_sk = s2.s_store_sk
    GROUP BY s2.s_store_id
)
-- 3️⃣ Final result: keep only rows from sales_agg that are not present in store_full (EXCEPT)
SELECT
    sa.s_store_id,
    sa.total_sales,
    sa.total_return_amount,
    sa.order_cnt
FROM sales_agg sa
EXCEPT
SELECT
    sf.s_store_id,
    CAST(sf.total_return_qty AS decimal(7,2)),
    CAST(NULL AS decimal(7,2)),
    CAST(NULL AS integer)
FROM store_full sf
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
