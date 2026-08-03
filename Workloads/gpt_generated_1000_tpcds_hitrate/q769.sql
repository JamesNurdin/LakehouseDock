/*
Goal: Identify the top‑earning customers per year by aggregating store sales profit together with catalog sales tax and store return tax, enriched with demographic income categories, call‑center location and promotion information. The query joins all nine TPC‑DS tables, applies multiple filters, uses a CTE for pre‑aggregating store sales, employs a CASE expression for income tier, computes a CUBE of all dimension combinations, includes an EXISTS subquery, and ranks the results with window functions.
*/
WITH ss_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_customer_sk,
        ss_store_sk,
        SUM(ss_net_profit)          AS total_net_profit,
        SUM(ss_quantity)            AS total_quantity
    FROM store_sales
    WHERE ss_quantity > 0                         -- filter predicate 1
    GROUP BY ss_sold_date_sk, ss_customer_sk, ss_store_sk
),
joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        cc.cc_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Low' END AS income_category,   -- CASE expression
        ss_agg.total_net_profit,
        cs.cs_ext_tax,
        sr.sr_return_tax,
        d.d_date,
        ss_agg.ss_sold_date_sk
    FROM ss_agg
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = ss_agg.ss_sold_date_sk
       AND ss.ss_customer_sk = ss_agg.ss_customer_sk
       AND ss.ss_store_sk    = ss_agg.ss_store_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = ss.ss_sold_date_sk
       AND cs.cs_bill_customer_sk = ss.ss_customer_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number   = ss.ss_ticket_number
       AND sr.sr_returned_date_sk = ss.ss_sold_date_sk
    JOIN customer c
        ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d
        ON d.d_date_sk = ss.ss_sold_date_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN promotion p
        ON p.p_promo_sk = ss.ss_promo_sk
    JOIN call_center cc
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    WHERE d.d_year BETWEEN 2001 AND 2002                         -- filter predicate 2
      AND cc.cc_state = 'CA'                                      -- filter predicate 3
      AND ib.ib_lower_bound >= 30000                               -- filter predicate 4
      AND cs.cs_ext_tax > 0                                        -- filter predicate 5
      AND EXISTS (                                                 -- subquery predicate 6
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = c.c_customer_sk
              AND sr2.sr_return_tax > 50
        )
),
cube_agg AS (
    SELECT
        d_year,
        d_month_seq,
        c_customer_id,
        cc_state,
        ib_income_band_sk,
        income_category,
        total_net_profit,
        cs_ext_tax,
        sr_return_tax,
        SUM(total_net_profit) AS sum_profit,
        COUNT(*)               AS cnt_rows
    FROM joined_data
    GROUP BY CUBE (
        d_year,
        d_month_seq,
        c_customer_id,
        cc_state,
        ib_income_band_sk,
        income_category,
        total_net_profit,
        cs_ext_tax,
        sr_return_tax
    )
)
SELECT
    d_year,
    d_month_seq,
    c_customer_id,
    cc_state,
    ib_income_band_sk,
    income_category,
    total_net_profit,
    cs_ext_tax,
    sr_return_tax,
    sum_profit,
    cnt_rows,
    RANK() OVER (PARTITION BY d_year ORDER BY sum_profit DESC) AS profit_rank_year,
    ROW_NUMBER() OVER (ORDER BY sum_profit DESC)           AS overall_rank
FROM cube_agg
WHERE sum_profit IS NOT NULL
ORDER BY d_year DESC, profit_rank_year
LIMIT 100
