WITH addr_sample AS (
    SELECT ca_address_sk, ca_state, ca_county
    FROM customer_address TABLESAMPLE BERNOULLI (10)
),
catalog_agg AS (
    SELECT
        cr.cr_order_number AS order_number,
        SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    FULL OUTER JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN addr_sample ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE td.t_sub_shift = 'evening'
      AND ca.ca_county = 'Taos County'
    GROUP BY cr.cr_order_number
),
web_agg AS (
    SELECT
        wr.wr_order_number AS order_number,
        SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    FULL OUTER JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN addr_sample ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE td.t_sub_shift = 'evening'
      AND ca.ca_county = 'Taos County'
    GROUP BY wr.wr_order_number
),
high_loss AS (
    SELECT order_number, net_loss
    FROM (
        SELECT order_number, net_loss FROM catalog_agg
        UNION ALL
        SELECT order_number, net_loss FROM web_agg
    ) AS all_combined
    WHERE net_loss > 1000
),
avg_loss AS (
    SELECT AVG(all_loss) AS avg_total_net_loss
    FROM (
        SELECT cr.cr_net_loss AS all_loss FROM catalog_returns cr
        UNION ALL
        SELECT wr.wr_net_loss FROM web_returns wr
    ) AS u
)
SELECT
    u.order_number,
    u.net_loss,
    a.avg_total_net_loss
FROM (
    SELECT order_number, net_loss FROM catalog_agg
    UNION DISTINCT
    SELECT order_number, net_loss FROM web_agg
    EXCEPT
    SELECT order_number, net_loss FROM high_loss
) AS u
CROSS JOIN avg_loss a
ORDER BY u.net_loss DESC
OFFSET 10
LIMIT 100
