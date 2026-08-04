/*
  Goal: Analyze catalog return performance by call center and return reason, focusing on high‑value returns.
  The query joins catalog_returns with call_center and reason, applies several realistic filter predicates,
  aggregates multiple monetary and count metrics (including distinct customer counts), orders by total return amount,
  and limits the result to the top 100 rows.
*/
WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_item_sk,
        cr_refunded_customer_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        cr_returning_customer_sk,
        cr_returning_cdemo_sk,
        cr_returning_hdemo_sk,
        cr_returning_addr_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_reason_sk,
        cr_order_number,
        cr_return_quantity,
        cr_return_amount,
        cr_return_tax,
        cr_return_amt_inc_tax,
        cr_fee,
        cr_return_ship_cost,
        cr_refunded_cash,
        cr_reversed_charge,
        cr_store_credit,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_store_credit > 100                     -- high store‑credit refunds
      AND cr_return_amount BETWEEN 50 AND 500      -- moderate‑to‑high return amounts
      AND cr_return_quantity >= 1                 -- at least one item returned
      AND cr_refunded_customer_sk IN (7942409, 6784621)  -- specific refunded customers
      AND cr_returning_customer_sk NOT IN (9999999)     -- exclude a placeholder ID
)
SELECT
    cc.cc_name,
    cc.cc_division_name,
    r.r_reason_desc,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT fr.cr_returning_customer_sk) AS distinct_returning_customers,
    COUNT(DISTINCT fr.cr_refunded_customer_sk) AS distinct_refunded_customers,
    MIN(fr.cr_return_quantity) AS min_return_quantity,
    MAX(fr.cr_return_amt_inc_tax) AS max_return_amount_inc_tax
FROM filtered_returns fr
JOIN call_center cc
  ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
  ON fr.cr_reason_sk = r.r_reason_sk
WHERE cc.cc_division_name = 'able'                           -- specific division
  AND cc.cc_mkt_class LIKE '%Citizens%'                       -- market class filter
  AND r.r_reason_desc LIKE '%size%'                           -- reason containing "size"
  AND cc.cc_state = 'CA'                                      -- only California centers (example)
  AND cc.cc_gmt_offset BETWEEN -5.00 AND -3.00                -- timezone filter
GROUP BY
    cc.cc_name,
    cc.cc_division_name,
    r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
