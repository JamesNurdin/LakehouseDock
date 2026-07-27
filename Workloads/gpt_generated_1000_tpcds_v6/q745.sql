WITH joined AS (
    SELECT
        c.c_customer_id,
        c.c_birth_year,
        r.r_reason_desc,
        cr.cr_net_loss,
        wr.wr_net_loss,
        td.t_hour,
        -- scalar subquery: total number of web returns for the customer
        (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk) AS web_return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
       AND wr.wr_returned_time_sk = td.t_time_sk
       AND wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%time%'
      AND c.c_birth_year > 1950
      AND td.t_hour BETWEEN 9 AND 17
      AND wr.wr_reversed_charge > 100
),
agg AS (
    SELECT
        c_customer_id,
        r_reason_desc,
        SUM(cr_net_loss) AS total_catalog_loss,
        SUM(wr_net_loss) AS total_web_loss,
        SUM(cr_net_loss + wr_net_loss) AS total_loss,
        MAX(web_return_cnt) AS web_return_cnt -- same per customer, just propagate
    FROM joined
    GROUP BY GROUPING SETS (
        (c_customer_id, r_reason_desc),
        (c_customer_id),
        (r_reason_desc),
        ()
    )
    HAVING SUM(cr_net_loss + wr_net_loss) > 0
)
SELECT
    DISTINCT c_customer_id,
    r_reason_desc,
    total_catalog_loss,
    total_web_loss,
    total_loss,
    web_return_cnt,
    RANK() OVER (PARTITION BY r_reason_desc ORDER BY total_loss DESC) AS loss_rank
FROM agg
WHERE c_customer_id IS NOT NULL
  AND r_reason_desc IS NOT NULL
ORDER BY total_loss DESC
LIMIT 100
