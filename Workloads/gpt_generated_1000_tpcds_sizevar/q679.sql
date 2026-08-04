WITH
  /* Sample a fraction of the store_sales fact table */
  sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- 10% random sample
  ),

  /* Ticket numbers that appear in both sales and returns */
  intersect_tickets AS (
    SELECT ss_ticket_number FROM store_sales
    INTERSECT
    SELECT sr_ticket_number FROM store_returns
  ),

  /* Keep all stores and their returns, even when one side is missing */
  full_store_ret AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      sr.sr_return_quantity,
      sr.sr_net_loss
    FROM store s
    FULL OUTER JOIN store_returns sr
      ON s.s_store_sk = sr.sr_store_sk
  ),

  /* Join every selected table to the household_demographics dimension (star schema) */
  joined1 AS (
    SELECT
      hd.hd_demo_sk,
      ss.ss_ticket_number,
      ss.ss_store_sk,
      ss.ss_hdemo_sk,
      ss.ss_ext_sales_price,
      sr.sr_return_quantity,
      sr.sr_net_loss,
      cs.cs_ext_sales_price,
      wr.wr_return_quantity,
      st.s_store_name
    FROM sampled_sales ss
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk                    -- rule: store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number        -- rule: store_returns.sr_ticket_number = store_sales.ss_ticket_number
    JOIN catalog_sales cs
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk              -- rule: catalog_sales.cs_bill_hdemo_sk = household_demographics.hd_demo_sk
    JOIN web_returns wr
      ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk         -- rule: web_returns.wr_returning_hdemo_sk = household_demographics.hd_demo_sk
    JOIN store st
      ON ss.ss_store_sk = st.s_store_sk                    -- rule: store_sales.ss_store_sk = store.s_store_sk
    WHERE ss.ss_ticket_number IN (SELECT ss_ticket_number FROM intersect_tickets)               -- subquery filter (IN)
      AND EXISTS (SELECT 1 FROM full_store_ret f WHERE f.s_store_sk = ss.ss_store_sk AND f.sr_net_loss IS NOT NULL)   -- EXISTS filter
      AND ss.ss_ext_sales_price > 1000                                                   -- predicate 1
      AND sr.sr_return_quantity > 0                                                       -- predicate 2
      AND cs.cs_ext_sales_price > 500                                                     -- predicate 3
      AND wr.wr_return_quantity > 0                                                       -- predicate 4
      AND hd.hd_vehicle_count >= 2                                                       -- predicate 5
  ),

  /* UNION distinct to force a deduplication step */
  unioned AS (
    SELECT
      hd_demo_sk,
      ss_ticket_number,
      ss_store_sk,
      ss_ext_sales_price,
      NULL AS extra_val
    FROM joined1
    UNION
    SELECT
      hd_demo_sk,
      ss_ticket_number,
      ss_store_sk,
      NULL,
      sr_net_loss
    FROM joined1
  ),

  /* Ranking and cumulative totals within each store */
  ranked AS (
    SELECT
      hd_demo_sk,
      ss_ticket_number,
      ss_store_sk,
      ss_ext_sales_price,
      extra_val,
      ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY COALESCE(ss_ext_sales_price, 0) DESC) AS sales_rank,
      SUM(COALESCE(ss_ext_sales_price, 0)) OVER (
        PARTITION BY ss_store_sk
        ORDER BY COALESCE(ss_ext_sales_price, 0)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS cumulative_sales
    FROM unioned
  ),

  /* Aggregate using GROUPING SETS */
  final_agg AS (
    SELECT
      hd_demo_sk,
      sales_rank,
      cumulative_sales,
      COUNT(*) AS cnt,
      SUM(COALESCE(ss_ext_sales_price, 0)) AS total_sales,
      SUM(COALESCE(extra_val, 0)) AS total_extra
    FROM ranked
    GROUP BY GROUPING SETS (
      (hd_demo_sk, sales_rank),
      (hd_demo_sk, cumulative_sales),
      ()
    )
  )
SELECT
  hd_demo_sk,
  sales_rank,
  cumulative_sales,
  cnt,
  total_sales,
  total_extra
FROM final_agg
WHERE cnt > 1
ORDER BY total_sales DESC
LIMIT 100
