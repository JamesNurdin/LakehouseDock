/*
Goal: Analyze the profitability of items sold under promotions, broken down by item, customer state, and promotion. The query joins store sales, web returns, items, promotions, and customer addresses, applies multiple filters, computes aggregated metrics in a CTE, then further filters and enriches the result with a scalar subquery, CASE logic, and an EXISTS check.
*/
WITH sales_returns AS (
    SELECT
        i.i_item_id,
        ca.ca_state,
        p.p_promo_id,
        SUM(ss.ss_ext_sales_price)                         AS total_sales,
        SUM(ss.ss_ext_discount_amt)                        AS total_discount,
        SUM(ss.ss_net_profit)                               AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number)                AS num_tickets,
        SUM(wr.wr_return_amt)                               AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number)                 AS num_returns,
        CASE
            WHEN SUM(ss.ss_net_profit) > 0 THEN 'POSITIVE'
            ELSE 'NEGATIVE'
        END                                                AS profit_flag
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_current_price BETWEEN 10 AND 100
      AND p.p_channel_tv = 'N'
      AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL')
      AND p.p_purpose <> 'Unknown'
    GROUP BY i.i_item_id, ca.ca_state, p.p_promo_id
    HAVING SUM(ss.ss_ext_sales_price) > 500
)
SELECT
    sr.i_item_id,
    sr.ca_state,
    sr.p_promo_id,
    sr.total_sales,
    sr.total_profit,
    sr.profit_flag,
    (SELECT AVG(i2.i_wholesale_cost)
       FROM item i2
       WHERE i2.i_item_id = sr.i_item_id)                         AS avg_wholesale_cost,
    sr.total_profit / NULLIF(sr.total_sales, 0)                     AS profit_per_sales
FROM sales_returns sr
WHERE sr.total_sales > 1000
  AND sr.total_profit > 0
  AND sr.num_returns < 5
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_id = sr.p_promo_id
          AND p2.p_discount_active = 'Y'
      )
ORDER BY sr.total_sales DESC
LIMIT 100
