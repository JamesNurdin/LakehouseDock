WITH filtered_returns AS (
    SELECT
        wr.wr_refunded_addr_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_reason_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        ca.ca_state,
        ca.ca_gmt_offset,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        r.r_reason_desc
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE hd.hd_vehicle_count >= 2
      AND hd.hd_dep_count BETWEEN 1 AND 5
      AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
      AND r.r_reason_desc LIKE '%color%'
      AND wr.wr_return_quantity > 0
      AND wr.wr_net_loss > 0
      AND EXISTS (
          SELECT 1 FROM customer_address ca2
          WHERE ca2.ca_address_sk = wr.wr_returning_addr_sk
            AND ca2.ca_city IN ('Ash 8th', 'Main Second')
      )
)
SELECT
    ca_state,
    r_reason_desc,
    SUM(wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    CASE
        WHEN SUM(wr_net_loss) > 1000 THEN 'High'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (ORDER BY SUM(wr_net_loss) DESC) AS state_loss_rank
FROM filtered_returns
GROUP BY ca_state, r_reason_desc
HAVING SUM(wr_net_loss) > 500
ORDER BY total_net_loss DESC
LIMIT 100
