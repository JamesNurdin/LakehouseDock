WITH
  base AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state,
      cc.cc_gmt_offset,
      cs.cs_quantity,
      cs.cs_net_profit,
      cs.cs_ext_sales_price,
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      d1.d_year,
      sr.sr_returned_date_sk,
      sr.sr_return_amt_inc_tax,
      sr.sr_net_loss,
      sr.sr_item_sk
    FROM tpcds.call_center cc
    FULL OUTER JOIN tpcds.catalog_sales cs
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.date_dim d1
      ON cc.cc_closed_date_sk = d1.d_date_sk
    LEFT JOIN tpcds.store_returns sr
      ON sr.sr_returned_date_sk = d1.d_date_sk
    WHERE
      cc.cc_state = 'CA'                           -- predicate 1
      AND cc.cc_gmt_offset = -5.00                 -- predicate 2
      AND cs.cs_quantity > 10                     -- predicate 3
      AND cs.cs_net_profit > 100                  -- predicate 4
      AND d1.d_year = 2001                        -- predicate 5
      AND sr.sr_return_amt_inc_tax < 5000         -- predicate 6
  ),
  lateral_agg AS (
    SELECT
      b.*, 
      la.return_cnt
    FROM base b
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS return_cnt
      FROM tpcds.store_returns sr2
      WHERE sr2.sr_item_sk = b.sr_item_sk
    ) la ON TRUE
  ),
  diff_keys AS (
    SELECT cs_order_number AS order_key FROM tpcds.catalog_sales
    EXCEPT
    SELECT sr_ticket_number AS order_key FROM tpcds.store_returns
  ),
  aggregated AS (
    SELECT
      la.cc_name,
      la.cc_state,
      la.d_year,
      SUM(la.cs_ext_sales_price) AS total_sales,
      AVG(la.cs_net_profit) AS avg_profit,
      COUNT(DISTINCT la.cs_order_number) AS distinct_orders,
      SUM(CASE WHEN la.sr_return_amt_inc_tax > 1000 THEN la.sr_return_amt_inc_tax ELSE 0 END) AS high_return_sum,
      MAX(la.sr_net_loss) AS max_net_loss,
      la.return_cnt
    FROM lateral_agg la
    JOIN diff_keys dk ON la.cs_order_number = dk.order_key
    GROUP BY la.cc_name, la.cc_state, la.d_year, la.return_cnt
  ),
  ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_sales DESC) AS rn
    FROM aggregated
    WHERE total_sales > 10000
  )
SELECT
  cc_name,
  cc_state,
  d_year,
  total_sales,
  avg_profit,
  distinct_orders,
  high_return_sum,
  max_net_loss,
  return_cnt,
  rn
FROM ranked
WHERE rn <= 5
LIMIT 100
