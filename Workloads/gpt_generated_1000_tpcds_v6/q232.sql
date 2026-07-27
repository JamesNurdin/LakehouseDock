WITH addr_filtered AS (
    SELECT ca_address_sk,
           ca_state,
           ca_county,
           ca_suite_number
    FROM   customer_address
    WHERE  ca_county IN ('Madison County', 'Maricopa County', 'York County')
       AND ca_suite_number LIKE 'Suite %'
),
agg_returns AS (
    SELECT
        ca.ca_state,
        ca.ca_county,
        sm.sm_type,
        SUM(cr.cr_return_amount)                                 AS total_catalog_return_amount,
        SUM(wr.wr_return_amt)                                    AS total_web_return_amount,
        COUNT(DISTINCT cr.cr_order_number)                       AS catalog_orders,
        COUNT(DISTINCT wr.wr_order_number)                       AS web_orders,
        AVG(CASE WHEN cr.cr_fee > 50 THEN cr.cr_fee END)        AS avg_high_fee,
        SUM(cr.cr_net_loss + wr.wr_net_loss)                    AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss + wr.wr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM   catalog_returns cr
    JOIN   addr_filtered ca   ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN   ship_mode sm       ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN   web_returns wr    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE  cr.cr_fee BETWEEN 30 AND 100
      AND  cr.cr_store_credit > 20
      AND  wr.wr_returning_customer_sk IN (1868887, 10887084, 3731623)
      AND  sm.sm_carrier = 'UPS'
      AND  EXISTS (
            SELECT 1
            FROM   web_returns wr2
            WHERE  wr2.wr_returning_addr_sk = ca.ca_address_sk
              AND  wr2.wr_return_amt > 500
        )
    GROUP BY ca.ca_state, ca.ca_county, sm.sm_type
    HAVING SUM(cr.cr_net_loss + wr.wr_net_loss) > 0
)
SELECT
    ar.ca_state,
    ar.ca_county,
    ar.sm_type,
    ar.total_catalog_return_amount,
    ar.total_web_return_amount,
    ar.catalog_orders,
    ar.web_orders,
    ar.avg_high_fee,
    ar.total_net_loss,
    ar.loss_category,
    ROW_NUMBER() OVER (PARTITION BY ar.ca_county ORDER BY ar.total_net_loss DESC) AS rn_county
FROM   agg_returns ar
ORDER BY ar.total_net_loss DESC
LIMIT 100
