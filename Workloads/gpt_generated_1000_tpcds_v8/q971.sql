/*
Goal: Identify the top‑ranking customers for the year 2001 by store net profit, filtering on meaningful business criteria, while demonstrating advanced SQL features such as TABLESAMPLE, window ranking, scalar sub‑queries, set operations (UNION / EXCEPT), DISTINCT, and pagination.
*/
WITH sampled_cp AS (
    SELECT *
    FROM catalog_page TABLESAMPLE BERNOULLI (10)
    WHERE cp_type = 'A'                -- predicate on catalog page type
),
top_store AS (
    SELECT DISTINCT ss_customer_sk AS cust_sk
    FROM store_sales ss
    WHERE ss_net_profit > 100          -- predicate on store profit
),
top_web AS (
    SELECT DISTINCT ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    WHERE ws_net_profit > 100          -- predicate on web profit
),
combined_cust AS (
    SELECT cust_sk FROM top_store
    UNION
    SELECT cust_sk FROM top_web
),
final_cust AS (
    SELECT cust_sk FROM combined_cust
    EXCEPT
    SELECT sr_customer_sk FROM store_returns
),
joined_data AS (
    SELECT
        d.d_year,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.ss_quantity,
        cs.cs_quantity,
        ws.ws_quantity,
        sr.sr_return_amt,
        cp.cp_department,
        w.w_state,
        RANK() OVER (PARTITION BY d.d_year ORDER BY ss.ss_net_profit DESC)                AS profit_rank,
        (SELECT AVG(cs2.cs_net_paid)
         FROM catalog_sales cs2
         WHERE cs2.cs_sold_date_sk = d.d_date_sk)                                 AS avg_catalog_paid
    FROM date_dim d
    JOIN store_sales ss        ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN catalog_sales cs      ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN web_sales ws          ON ws.ws_sold_date_sk   = d.d_date_sk
    JOIN store_returns sr      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c            ON c.c_customer_sk      = ss.ss_customer_sk
    JOIN customer_address ca   ON ca.ca_address_sk     = ss.ss_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk     = ss.ss_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk   = ss.ss_hdemo_sk
    JOIN income_band ib        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN reason r              ON r.r_reason_sk        = sr.sr_reason_sk
    JOIN warehouse w           ON w.w_warehouse_sk     = cs.cs_warehouse_sk
    JOIN sampled_cp cp         ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    WHERE d.d_year = 2001                                   -- predicate on year
      AND ss.ss_quantity > 2                               -- predicate on store qty
      AND cs.cs_quantity > 2                               -- predicate on catalog qty
      AND ws.ws_quantity > 2                               -- predicate on web qty
      AND sr.sr_return_amt > 100                           -- predicate on return amount
      AND cp.cp_department = 'Books'                       -- predicate on catalog page dept
      AND w.w_state = 'CA'                                 -- predicate on warehouse location
      AND c.c_customer_sk IN (SELECT cust_sk FROM final_cust)  -- IN‑subquery filter
)
SELECT DISTINCT
    d_year,
    c_customer_sk,
    c_first_name,
    c_last_name,
    profit_rank,
    avg_catalog_paid
FROM joined_data
ORDER BY profit_rank
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
