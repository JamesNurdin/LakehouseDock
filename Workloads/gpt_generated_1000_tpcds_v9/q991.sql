WITH sampled_returns AS (
    SELECT cr.cr_returned_date_sk,
           cr.cr_refunded_addr_sk,
           cr.cr_returning_addr_sk,
           cr.cr_reason_sk,
           cr.cr_order_number,
           cr.cr_return_amount,
           cr.cr_net_loss
    FROM catalog_returns cr
    TABLESAMPLE BERNOULLI (10)
),
return_orders_us AS (
    SELECT cr.cr_order_number
    FROM sampled_returns cr
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
),
refund_big_amount AS (
    SELECT cr.cr_order_number
    FROM sampled_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND cr.cr_return_amount > 2000
),
intersect_orders AS (
    SELECT cr_order_number
    FROM return_orders_us
    INTERSECT
    SELECT cr_order_number
    FROM refund_big_amount
),
filtered_returns AS (
    SELECT cr.cr_order_number,
           cr.cr_net_loss,
           cr.cr_reason_sk,
           d.d_year,
           d.d_quarter_seq,
           r.r_reason_desc
    FROM sampled_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN intersect_orders io ON cr.cr_order_number = io.cr_order_number
    WHERE d.d_year = 2000
      AND d.d_quarter_seq = 8
),
aggregated AS (
    SELECT fr.r_reason_desc,
           SUM(fr.cr_net_loss) AS total_net_loss
    FROM filtered_returns fr
    GROUP BY fr.r_reason_desc
),
final AS (
    SELECT a.r_reason_desc,
           a.total_net_loss,
           CASE WHEN a.total_net_loss > 5000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM aggregated a
)
SELECT f.r_reason_desc,
       f.total_net_loss,
       f.loss_category,
       SUM(f.total_net_loss) OVER (
           PARTITION BY f.loss_category
           ORDER BY f.total_net_loss DESC
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total_net_loss
FROM final f
ORDER BY f.total_net_loss DESC
LIMIT 100
