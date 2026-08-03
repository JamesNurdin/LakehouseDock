WITH base AS (
  SELECT
    COALESCE(c.c_customer_sk, -1) AS customer_sk,
    COALESCE(c.c_first_name, 'Unknown') AS first_name,
    COALESCE(ca.ca_state, 'Unknown') AS state,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  FULL OUTER JOIN customer c
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE
    wr.wr_return_ship_cost > 500
    AND wr.wr_return_amt_inc_tax BETWEEN 1000 AND 3000
    AND (c.c_birth_year BETWEEN 1970 AND 1990 OR c.c_birth_year IS NULL)
    AND ca.ca_state IN ('CA','NY','TX')
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
  GROUP BY
    COALESCE(c.c_customer_sk, -1),
    COALESCE(c.c_first_name, 'Unknown'),
    COALESCE(ca.ca_state, 'Unknown')
  HAVING SUM(wr.wr_net_loss) > 1000
),
ranked AS (
  SELECT
    b.*,
    ROW_NUMBER() OVER (ORDER BY b.total_net_loss DESC) AS rn
  FROM base b
)
SELECT
  r.customer_sk,
  r.first_name,
  r.state,
  r.total_net_loss,
  r.return_cnt,
  r.rn,
  dim.tier,
  r.total_net_loss * dim.multiplier AS weighted_loss
FROM ranked r
CROSS JOIN (
  VALUES
    (1, 'Low', 0.5),
    (2, 'Medium', 1.0),
    (3, 'High', 1.5)
) AS dim(id, tier, multiplier)
WHERE r.rn = dim.id
ORDER BY r.total_net_loss DESC
OFFSET 0 LIMIT 100
