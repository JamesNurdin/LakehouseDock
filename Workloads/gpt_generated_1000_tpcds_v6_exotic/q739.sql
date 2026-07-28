/* goal: Analyze combined store and web return performance by customer state and gender, identifying high‑value return groups and filtering on several demographic and transaction criteria */
WITH joined_data AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_store_credit,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        hd.hd_vehicle_count,
        ca.ca_state,
        ca.ca_country,
        wr.wr_return_amt,
        wr.wr_account_credit,
        wp.wp_type,
        wp.wp_rec_start_date
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_returns wr ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE sr.sr_return_tax > 5
      AND sr.sr_store_credit < 500
      AND cd.cd_purchase_estimate >= 6000
      AND hd.hd_vehicle_count <= 2
      AND wp.wp_rec_start_date > DATE '2020-01-01'
      AND cd.cd_gender IN (
          SELECT DISTINCT gender FROM (
              SELECT cd1.cd_gender AS gender FROM customer_demographics cd1 WHERE cd1.cd_dep_count > 1
              UNION
              SELECT cd2.cd_gender FROM customer_demographics cd2 WHERE cd2.cd_dep_count = 0
          )
      )
),
agg_by_state_gender AS (
    SELECT
        ca_state AS state,
        cd_gender AS gender,
        COUNT(*) AS cnt,
        SUM(sr_return_amt) AS total_store_return,
        SUM(wr_return_amt) AS total_web_return,
        AVG(CASE WHEN sr_return_amt > 100 THEN 1 ELSE 0 END) AS high_store_return_ratio
    FROM joined_data
    GROUP BY ca_state, cd_gender
    HAVING COUNT(*) > 10
)
SELECT DISTINCT
    ag.state,
    ag.gender,
    ag.cnt,
    ag.total_store_return,
    ag.total_web_return,
    ag.high_store_return_ratio,
    CASE
        WHEN ag.total_store_return > 1000 THEN 'Big'
        ELSE 'Small'
    END AS size_category,
    (
        SELECT MAX(purchase_est) FROM (
            SELECT DISTINCT cd_purchase_estimate AS purchase_est FROM customer_demographics
        )
    ) AS max_purchase_estimate_global
FROM agg_by_state_gender ag
WHERE EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_return_amt > ag.total_store_return
      AND sr2.sr_customer_sk = (
          SELECT MAX(sr3.sr_customer_sk) FROM store_returns sr3
      )
)
ORDER BY ag.total_store_return DESC
LIMIT 100
