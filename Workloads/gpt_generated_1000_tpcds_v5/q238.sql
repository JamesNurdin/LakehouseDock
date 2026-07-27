/* goal: Analyze web returns by US state and return reason, measuring financial impact and order counts for daytime (9‑17) returns that mention "color" in the reason, while incorporating promotion information. */
WITH filtered_returns AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = wr.wr_item_sk
          AND p2.p_response_target > 5
    )
)
SELECT
    ca.ca_state,
    r.r_reason_desc,
    COALESCE(p.p_discount_active, 'N') AS promo_active_flag,
    COUNT(DISTINCT fr.wr_order_number) AS return_orders,
    SUM(fr.wr_return_amt) AS total_return_amount,
    AVG(fr.wr_return_quantity) AS avg_return_qty,
    MIN(fr.wr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(fr.wr_net_loss) AS max_net_loss
FROM filtered_returns fr
JOIN time_dim t
  ON fr.wr_returned_time_sk = t.t_time_sk
JOIN item i
  ON fr.wr_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
  AND p.p_purpose = 'Clearance'
JOIN reason r
  ON fr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp
  ON fr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer c_ref
  ON fr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_address ca
  ON c_ref.c_current_addr_sk = ca.ca_address_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND ca.ca_country = 'United States'
  AND r.r_reason_desc LIKE '%color%'
GROUP BY ca.ca_state, r.r_reason_desc, COALESCE(p.p_discount_active, 'N')
ORDER BY total_return_amount DESC
LIMIT 100
